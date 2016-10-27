require 'RMagick'
require 'fileutils'

class FlyerImage

  def self.create_image(img_txt)

    path = File.expand_path("#{File.dirname(__FILE__)}/StoryTime-invite-packet.png")

    img = Magick::Image.ping( path ).first
    width = img.columns
    height = img.rows

    canvas = Magick::Image.from_blob(IO.read(path))[0]

    text = Magick::Draw.new
    # text.font_family = 'helvetica'
    text.font = File.expand_path("#{File.dirname(__FILE__)}/../../public/fonts/AvenirLTStd-Medium.otf")
    text.pointsize = 36
    # text.gravity = Magick::CenterGravity

    x_start, x_end = 185, 383
    # 185, 427
    # 185, 462
    y_start, y_end = 382, 369

    text.annotate(canvas, 0, 0, 185, 420, "To get stories by")


    dimensions = text.get_type_metrics("text, text ")
    text.annotate(canvas, 0, 0, 185, 462, "text, text ")
    text.font = File.expand_path("#{File.dirname(__FILE__)}/../../public/fonts/AvenirLTStd-Black.otf")
    img_txt_d = text.get_type_metrics("#{img_txt}")
    text.annotate(canvas, 0, 0, 185 + dimensions.width, 462, "#{img_txt}")
    # text.annote
    text.font = File.expand_path("#{File.dirname(__FILE__)}/../../public/fonts/AvenirLTStd-Medium.otf")
    text.annotate(canvas, 0, 0, 185, 507, "to (203)-202-3505")


    # 597 x 553
    text.font = File.expand_path("#{File.dirname(__FILE__)}/../../public/fonts/AvenirLTStd-Black.otf")
    text.annotate(canvas, 0, 0, 605, 580, img_txt)

    # img_path = File.expand_path("#{File.dirname(__FILE__)}/../../public/enroll-flyer/#{img_txt}-flyer.png")

    flyers = S3.bucket('teacher-materials')

    if flyers.exists?
        name = "flyers/#{img_txt}-flyer.png"
        if flyers.object(name).exists?
            puts "#{name} already exists in the bucket"
        else
          obj = flyers.object(name)
          obj.put(body: canvas.to_blob, acl: "public-read")
          puts "Uploaded '%s' to S3!" % name
        end

        pdf = Magick::ImageList.new
        pdf.from_blob(canvas.to_blob)
        tmpfile = File.expand_path("#{File.dirname(__FILE__)}/#{img_txt}.pdf")
        pdf.write(tmpfile)
        # pdf += canvas
        name = "flyers/#{img_txt}-flyer.pdf"
        if flyers.object(name).exists?
            puts "#{name} already exists in the bucket"
        else
          obj = flyers.object(name)
          # obj.put(body: pdf.to_blob, acl: "public-read")
          obj.upload_file(tmpfile, acl: "public-read")
          puts "Uploaded '%s' to S3!" % name
        end

        FileUtils.rm(tmpfile)

    end

  end

end

class PhoneImage

  def self.create_image(img_txt)

    path = File.expand_path("#{File.dirname(__FILE__)}/phone-text-blank.png")

    img = Magick::Image.ping( path ).first
    width = img.columns
    height = img.rows

    canvas = Magick::Image.from_blob(IO.read(path))[0]
    text = Magick::Draw.new
    text.font = File.expand_path("#{File.dirname(__FILE__)}/../../public/fonts/AvenirLTStd-Black.otf")
    text.pointsize = 45

    dimensions = text.get_type_metrics(img_txt)

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

    # we do the amazon stuff here
    flyers = S3.bucket('teacher-materials')

    if flyers.exists?
        name = "phone-imgs/#{img_txt}-phone.png"
        if flyers.object(name).exists?
            puts "#{name} already exists in the bucket"
        else
          obj = flyers.object(name)
          obj.put(body: canvas.to_blob, acl: "public-read")
          puts "Uploaded '%s' to S3!" % name
        end
    end

  end

end 