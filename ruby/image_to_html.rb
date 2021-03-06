=begin
image to html scripts.

require: rubygems, rmagick
=end

require 'rubygems'
require 'RMagick'
include Magick


img = Image.read(ARGV[0]).first
html =  "<html><style><!-- *{margin:0;padding:0;}td{width:1px;}tr{height:1px;} --></style><body><table cellspacing=\"0\" cellpadding=\"0\">\n"
img.rows.times do |r|
  html += "<tr>\n"
  img.columns.times do |c|
    pixel = img.pixel_color(c+1, r+1)
    html += "<td style=\"background-color: #{img.to_color(pixel)};\"></td>\n"
  end
  html += "</tr>\n"
end
html += "</table></body></html>"

File.open('image.html',"w"){|f| f.puts html }
