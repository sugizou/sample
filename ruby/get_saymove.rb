#!/usr/bin/env ruby
help_message = <<EOF

saymoveからflvを引っこ抜きます。
引っこ抜かれたファイルは動画を再生するページのタイトルから「 SayMove!」を削ったものに.flvをつけたものになります。

timeout、エラー処理はされてません。
またURLを解釈できなかった場合はスルーします

#履歴#
2010/02/18 0.0.4 -P指定時のバグ改修。ファイルを取得できなかった時の挙動を変更。-t(タグ検索)を追加。ファイル名に「\」や「/」が含まれてたときにそれらを置換するように変更。

2010/02/18 0.0.3 -s指定時のバグ改修。プログレスバーの追加(ダウンロードの進捗確認用)

2010/02/17 0.0.2 オプションを解釈するようにしました。これにより、動画単体か検索一覧の全取得、保存先の指定、ログ出力の有無、検索時に取得する最大ページ数を指定できます。

2010/02/14 0.0.1 初回作成

EOF

$KCODE = 'u'
SAYMOVE_VERSION = "0.0.3"
require 'net/http'
require 'optparse'
require 'uri'
require 'kconv'
require 'pathname'
require 'rubygems'
require 'hpricot'
#require 'mechanize'

class SayMove
  attr_accessor :http, :opt

  URL_LIST = {
    :search => '/comesearch.php?sort=toukoudate&genre=&sitei=&mode=%s&q=%s&p=%s',
    :detail => '/comeplay.php?comeid=%s',
    :flvurl => '/get/gettest.php?%s'
  }
  
  def initialize(opt)
    @http = Net::HTTP.new('say-move.org', 80)
    @opt  = opt
  end
  
  def list(word, page, mode = "")
    html = @http.get(sprintf(SayMove::URL_LIST[:search], mode, URI.encode(word.tosjis), page.to_s))

    SayMove.log("検索結果 : #{word}", @opt[:quiet])

    list = Hpricot(html.body)
    return false if (list/"table/tr").size < 1 || (list/"table/tr/td").size < 2
    tr = (list/"table/tr")
    info = []
    tr.each do |row|
      for i in [2,4,6]
        a = (row/"td[#{i}]/p/a[1]")
        next if a.empty?
        url = URI.parse((a.first)[:href])

        /comeid=([^&]+)/ =~ url.query
        id = $1

        unless id
          SayMove.log("#{url.request_uri} : comeidが取得できません。スキップしました。", @opt[:quiet])
          next
        end

        info.push(id)

        SayMove.log("#{url.request_uri} : #{id} をセットしました。", @opt[:quiet])
      end
    end

    info
  end
  
  def get_flv(id)
    path = @opt[:path]
    html = @http.get(sprintf(SayMove::URL_LIST[:detail], id.to_s))
    detail = Hpricot(html.body)
    
    title = (detail/"title").inner_text.sub(' SayMove!','').strip
    
    flashvars = ""
    (detail/"object/param").each{|s|
      if s[:name] == 'FlashVars'
        flashvars = s[:value]
        SayMove.log("#{title} : FlashVarsの取得に成功しました。FLVのURLを取得します。", @opt[:quiet])
      end
    }
    
    if flashvars == ''
      SayMove.log("#{title} : FlashVarsが存在しません。FLVの取得に失敗しました。", @opt[:quiet])
      return false
    end
    
    html = @http.get(sprintf(SayMove::URL_LIST[:flvurl], flashvars.to_s))
    
    />([^>]+)</ =~ html.body
    if $1.nil? || $1.empty?
      SayMove.log("#{title} : URLの取得に失敗しました[#{sprintf(SayMove::URL_LIST[:flvurl], flashvars.to_s)}]", @opt[:quiet])
      return false
    end
    url = URI.parse($1.strip)
    
    SayMove.log("#{title} : 動画のURLの取得に成功しました[#{url.to_s}]", @opt[:quiet])
    
    http = Net::HTTP.new(url.host, 80)
    head = http.head(url.to_s)
    max_size = head['content-length'].to_i
    now_size = 0
    
    if max_size <= 0
      SayMove.log("#{title} : ファイルがありません。スキップします。")
      return false
    end
    
    SayMove.log("#{title} : ダウンロード開始します。", @opt[:quiet])

    f = File.open(path.realpath.to_s + "/" +  SayMove.fileescape(title).toutf8 + ".flv", 'w')

    http.get(url.to_s) {|res|
      now_size = now_size + res.size
      SayMove.progress(title, now_size, max_size, 20)
      f.write res
    }
    
    SayMove.log("#{title} : ダウンロード成功", false)
  end

  def self.log(str, quiet)
    puts str unless quiet
  end
  
  def self.progress(title, now, max, sep)
    tpl  = "%s : [%s] %s%s%s";
    rate = (100.0 /sep.to_i)
    per  = (now.to_f / max) * 100
    
    cnt = 0
    
    if per.infinite? && per.infinite? > 0
      STRERR.print "no information...\r"
    end
    
    if per.nan?
      STDERR.print sprintf(tpl, title, "waiting.." + " " * (sep - 10), "0/#{max.to_s}", "0%", "\r")
    end
    
    if per.to_i == 100
      STDERR.print " " * 200, "\r"
      STDERR.print sprintf(tpl, title,  ">" * sep, "(completed)", "100%", "\n")
      return
    end
    
    cnt = (per / rate).to_i
    STDERR.print sprintf(tpl, title, (">" * cnt) + (" " * (sep - cnt)), "(#{now.to_s}/#{max.to_s})", per.to_i.to_s + "%",  "\r")
  end
  
  def self.fileescape(str)
    return str.gsub('/', '／').gsub('\\', '＼')
  end
end

###
# script
###

#option parse
option = {}
opt = OptionParser.new

opt.on('-s','--search WORDS','Search SayMove. And search result list download for all.'){|s|
  option[:words] = s.toutf8
  if option[:words].nil? || option[:words] == ''
    puts "-s option augument invalid."
    exit
  end
}

opt.on('-t', '--tag TAG', 'Tag search from SayMove!. And search result list download from all.'){|t|
  option[:tag] = t.toutf8
  if option[:tag].nil? || option[:tag] == ''
    puts "-t option augument invaild."
    exit
  end
}

opt.on('-c','--comeid ID', 'Movie page parameter "comeid" setting.') {|c|
  option[:comeid] = c
  if option[:comeid].nil? || option[:comeid] == '' || /^\d+/ !~ option[:comeid]
    puts "-c option augument invalid."
    exit
  end
}
opt.on('-q','--quiet', 'Quiet output.') {|q| option[:quiet] = true}
opt.on('-p','--page NUM', 'Search Samove list max page number.') {|n| option[:page] = n || 10}
opt.on('-P','--path [PATH]', 'download file path setting for save.') {|path| option[:path] = path || "./"}
opt.on_tail('-v','--version','get_saymove.rb Version') do 
  puts SAYMOVE_VERSION
  exit
end
opt.on_tail('-h','--help', "#{help_message.to_s}") do 
  puts opt
  exit
end
opt.parse!(ARGV)

#option validations
option[:page]||= 10
option[:path]||= './'
option[:path] = Pathname.new(option[:path])
option[:quiet]||= false
if option[:words].nil? && option[:comeid].nil? && option[:tag].nil?
  puts 'require option: -s or -c or t.'
  exit
end

saymove = SayMove.new(option)
if option[:words]
  1.upto(option[:page].to_i) {|page|
    ids = saymove.list(option[:words], page)
    ids.each do |id|
      saymove.get_flv(id)
    end
  }
elsif option[:tag]
  1.upto(option[:page].to_i) {|page|
    ids = saymove.list(option[:tag], page, "tag")
    ids.each do |id|
      saymove.get_flv(id)
    end
  }
elsif option[:comeid]
  saymove.get_flv(option[:comeid])
end

