require 'rubygems'
require 'rmagick'
require 'fileutils'

if ARGV.count != 1
  puts "Usage: ruby make_scrim.rb [shortcut-android repo location]"
  puts
  puts "Should be relative to the location of this file."
  exit
end

REPO_PATH = ARGV.first
FNAME  = File.expand_path(File.join("..", "EventRowScrim.png"), __FILE__)
ASSETS = File.expand_path(
  File.join("..", REPO_PATH, "app", "src", "main", "res"),
  __FILE__
)

RES = "event_row_scrim.9.png"

def path(bucket, res)
  File.join(ASSETS, "drawable-#{bucket}", res)
end

{
  mdpi:   [30, 120],
  hdpi:   [45, 180],
  xhdpi:  [60, 240],
  xxhdpi: [90, 360]
}.each_with_object(
  Magick::Image.read(FNAME).first
) do |(bucket, (w, h)), orig|
  puts "Resource #{bucket} => (#{w}, #{h})"

  res_path = path(bucket, RES)
  resized  = orig.resize(w, h).border(1,1, "transparent")

  Magick::Draw.new
    .fill('black')
    .point(0,1).point(1,0)
    .draw(resized)

  bckp_path = nil
  if File.exists?(res_path)
    puts "Moving current: #{res_path}"
    bckp_path = path(bucket, "~#{RES}")
    File.rename(res_path, bckp_path)
  end

  begin
    resized.write(res_path)
    puts "Written to: #{res_path}"

    if bckp_path
      puts "Cleaning up backup"
      FileUtils.rm(bckp_path)
      bckp_path = nil
    end
  ensure
    if bckp_path
      puts "Reverting old version"
      File.rename(bckp_path, res_path)
    end
  end
end
