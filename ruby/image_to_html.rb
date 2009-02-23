=begin
image to html scripts.

require: rubygems, rmagick
=end

require 'rubygems'
require 'RMagick'
include Magick


img = Image.read('ruby.jpg').first
puts "<html><body><table cellspacing=\"0\" cellpadding=\"0\" border=\"1\">"
img.rows.times do |r|
  puts "<tr>"
  img.columns.times do |c|
    pixel = img.pixel_color(c+1, r+1)
    puts "<td style=\"background-color: #{img.to_color(pixel)};\"></td>"
  end
  puts "</tr>"
end
puts "</table></body></html>"
