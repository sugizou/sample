=begin
image to html scripts.

require: rubygems, rmagick
=end

require 'rubygems'
require 'RMagick'
include Magick


img = Image.read(ARGV[0]).first
html =  "<html><body><table cellspacing=\"0\" cellpadding=\"0\" border=\"1\">\n"
img.rows.times do |r|
  html += "<tr>\n"
  img.columns.times do |c|
    pixel = img.pixel_color(c+1, r+1)
    html += "<td style=\"background-color: #{img.to_color(pixel)};\"></td>\n"
  end
  html += "</tr>\n"
end
html += "</table></body></html>"

f = File.open('image.html',"w")
f.puts html
f.close
