require 'RMagick'
class PhoneImage

  def self.create_image(img_txt)

    path = File.expand_path("#{File.dirname(__FILE__)}/phone-text-blank.png")

    img = Magick::Image.ping( path ).first
    width = img.columns
    height = img.rows

    phone = Magick::ImageList.new(path)
    canvas = Magick::ImageList.new
    canvas.new_image(width, height, Magick::TextureFill.new(phone))

    text = Magick::Draw.new
    text.font_family = 'helvetica'
    text.pointsize = 45
    # text.gravity = Magick::CenterGravity

    gc = Magick::Draw.new
    gc.font = ("helvetica")
    gc.pointsize = 45

    dimensions = gc.get_type_metrics(img_txt)

    x_start, x_end = 106, 324
    y_start, y_end = 290, 369

    center = {
      x: (x_start + x_end) / 2.0,
      y: (y_start + y_end) / 2.0
    }

    x = center[:x] - (dimensions.width  / 2.0)
    y = center[:y] + ((dimensions.ascent - dimensions.descent) / 2.0) - 10

    text.annotate(canvas, 106,290,x,y, img_txt) {
      self.fill = 'white'
    }



    canvas.write(File.expand_path("#{File.dirname(__FILE__)}/../../public/enroll-phone/#{img_txt}-enroll.png"))

  end

end 