require 'RMagick'
require 'fileutils'

class FlyerImage

  def self.create_image(img_txt)

    path = File.expand_path("#{File.dirname(__FILE__)}/StoryTime-invite-packet.png")

    img = Magick::Image.ping( path ).first
    width = img.columns
    height = img.rows

    flyer = Magick::ImageList.new(path)
    canvas = Magick::ImageList.new
    canvas.new_image(width, height, Magick::TextureFill.new(flyer))

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

    # [[383, "To get stories by"], [427, "text, text #{img_txt} to"], [472, "(203)-202-3505"]].each do |y|
    #     text.annotate(canvas, 0, 0, 185, y[0] + 35, y[1])
    # end

    # 597 x 553
    text.font = File.expand_path("#{File.dirname(__FILE__)}/../../public/fonts/AvenirLTStd-Black.otf")
    text.annotate(canvas, 0, 0, 605, 580, img_txt)

    img_path = File.expand_path("#{File.dirname(__FILE__)}/../../public/enroll-flyer/#{img_txt}-flyer.png")
    begin
        old_image = Magick::Image.read(img_path)
        if old_image.size > 0 # image exists
            diff = (old_image[0] <=> canvas[0])
            puts "searching old images..."
            puts "difference is #{diff.inspect}"

            if diff == 0
                puts "we don't need to rewrite #{img_txt}-flyer.png + .pdf"
                return
            else
                puts "creating new image #{img_txt}-flyer.png + .pdf"
            end
        end
    rescue => e
        puts "creating new image #{img_txt}-flyer.png + .pdf"
    end
    # begin
    #     img_path = File.expand_path("#{File.dirname(__FILE__)}/../../public/enroll-flyer/#{img_txt}-flyer.pdf")
    #     old_image = Magick::Image.read(img_path)
    #     if old_image.size > 0 # image exists
    #         diff = (old_image[0] <=> canvas[0])
    #         puts "searching old images..."
    #         puts "difference is #{diff.inspect}"

    #         if diff == 0
    #             puts "we don't need to rewrite #{img_txt}-flyer.pdf"
    #             return
    #         else
    #             puts "creating new image #{img_txt}-flyer.pdf"
    #         end
    #     end
    # rescue => e
    #     puts "creating new image #{img_txt}-flyer.pdf"
    # end
    dirname = File.expand_path("#{File.dirname(__FILE__)}/../../public/enroll-flyer")

    unless File.directory?(dirname)
      FileUtils.mkdir_p(dirname)
    end

    puts "writing images..."
    canvas.write("#{dirname}/#{img_txt}-flyer.png")
    canvas.write("#{dirname}/#{img_txt}-flyer.pdf")

  end

end

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
    text.font = File.expand_path("#{File.dirname(__FILE__)}/../../public/fonts/AvenirLTStd-Black.otf")
    text.pointsize = 45
    # text.gravity = Magick::CenterGravity

    # gc = Magick::Draw.new
    # gc.font = ("helvetica")
    # gc.pointsize = 45

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

    img_path = File.expand_path("#{File.dirname(__FILE__)}/../../public/enroll-phone/#{img_txt}-enroll.png")
    begin
        old_image = Magick::Image.read(img_path)
        if old_image.size > 0 # image exists
            diff = (old_image[0] <=> canvas[0])
            puts "searching old images..."
            puts "difference is #{diff.inspect}"

            if diff == 0
                puts "we don't need to rewrite #{img_txt}-enroll.png"
                return 
            else
                puts "creating new image #{img_txt}-enroll.png"
            end
        end
    rescue => e
        puts "creating new image #{img_txt}-enroll.png"
    end

    dirname = File.expand_path("#{File.dirname(__FILE__)}/../../public/enroll-phone")

    unless File.directory?(dirname)
      FileUtils.mkdir_p(dirname)
    end

    canvas.write("#{dirname}/#{img_txt}-enroll.png")

  end

end 