require 'RMagick'
require 'fileutils'
require_relative '../../config/initializers/aws'

# should phoneImages be stored in the teacher folders? seems a bit excessive for our purposes. 
class PhoneImage

  def self.create_image(teacher_obj, school_obj)
    img_txt = teacher_obj.code.split('|').first
    teacher = teacher_obj.signature
    school = school_obj.signature

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
        # in case a teacher has multiple classrooms (same signature), use their code to differentiate
        teacher_dir = "#{teacher}-#{teacher_obj.t_number}" 
        name = "#{school}/#{teacher_dir}/phone-imgs/#{img_txt}-phone.png"
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

class FlyerImage

  def self.create_image(teacher_obj, school_obj)
    code = teacher_obj.code
    teacher = teacher_obj.signature
    school = school_obj.signature

    code_en, code_es = code.split('|')

    puts "code_en = #{code_en}"
    puts "code_es = #{code_es}"

    path = File.expand_path("#{File.dirname(__FILE__)}/StoryTime-invite-packet2.png")

    img = Magick::Image.ping( path ).first
    width = img.columns
    height = img.rows

    canvas = Magick::Image.from_blob(IO.read(path))[0]

    text = Magick::Draw.new
    # text.font_family = 'helvetica'
    text.font = File.expand_path("#{File.dirname(__FILE__)}/../../public/fonts/AvenirLTStd-Medium.otf")
    text.pointsize = 62
    # text.gravity = Magick::CenterGravity

    x_start, x_end = 350, 383
    # 185, 427
    # 185, 462
    y_start, y_end = 1272, 369

    dimensions = text.get_type_metrics("To start, text ")
    text.annotate(canvas, 0, 0, x_start, y_start, "To start, text ")

    text.font = File.expand_path("#{File.dirname(__FILE__)}/../../public/fonts/AvenirLTStd-Black.otf")
    img_txt_d = text.get_type_metrics("#{code_en}")
    text.annotate(canvas, 0, 0, x_start + dimensions.width, y_start, "#{code_en}")
    # text.annote
    text.font = File.expand_path("#{File.dirname(__FILE__)}/../../public/fonts/AvenirLTStd-Medium.otf")
    dimensions = text.get_type_metrics("to ")
    text.annotate(canvas, 0, 0, x_start, y_start + 90, "to ")

    text.font = File.expand_path("#{File.dirname(__FILE__)}/../../public/fonts/AvenirLTStd-Black.otf")
    text.annotate(canvas, 0, 0, x_start + dimensions.width, y_start + 90, "(203)-202-3505")



    # 597 x 553
    # text.font = File.expand_path("#{File.dirname(__FILE__)}/../../public/fonts/AvenirLTStd-Black.otf")
    text.annotate(canvas, 0, 0, 1220, 1596, code_en)


    # then the upper title...
    # 200, 737
    # text.font = File.expand_path("#{File.dirname(__FILE__)}/../../public/fonts/AvenirLTStd-Black.otf")
    text.pointsize = 120
    text.annotate(canvas, 0, 0, 208, 717, "#{teacher}.")

    # 200, 875
    text.pointsize = 45
    text.font = File.expand_path("#{File.dirname(__FILE__)}/../../public/fonts/AvenirLTStd-Medium.otf")
    dimensions = text.get_type_metrics("Get books for ")
    text.annotate(canvas, 0, 0, 208, 875, "Get books for ")
    text.font = File.expand_path("#{File.dirname(__FILE__)}/../../public/fonts/AvenirLTStd-Black.otf")
    text.annotate(canvas, 0, 0, 208 + dimensions.width, 875, "#{school} ")

    text.font = File.expand_path("#{File.dirname(__FILE__)}/../../public/fonts/AvenirLTStd-Medium.otf")
    x_width = dimensions.width + text.get_type_metrics("#{school} ").width
    text.annotate(canvas, 0, 0, 208 + x_width, 875, "by text message and right on your phone-- not across town.")

    img_path = File.expand_path("#{File.dirname(__FILE__)}/../../public/enroll-flyer/#{code_en}-flyer.png")

    # canvas.write(img_path)

    # write .png to aws
    # 
    # 
    # 
    # 
    # end write to aws

    # spanish now 

    path = File.expand_path("#{File.dirname(__FILE__)}/StoryTime-invite-packet-es.png")

    img = Magick::Image.ping( path ).first
    width = img.columns
    height = img.rows

    canvas_es = Magick::Image.from_blob(IO.read(path))[0]
    # 208, 677
    # 
    text = Magick::Draw.new
    text.font = File.expand_path("#{File.dirname(__FILE__)}/../../public/fonts/AvenirLTStd-Medium.otf")
    text.pointsize = 62

    x_start, x_end = 350, 383
    # 185, 427
    # 185, 462
    y_start, y_end = 1272, 369

    text.annotate(canvas_es, 0, 0, x_start, y_start, "Para recibir cuentos, ")

    dimensions = text.get_type_metrics("textéa ")
    text.annotate(canvas_es, 0, 0, x_start, y_start + 90, "textéa ")
    text.font = File.expand_path("#{File.dirname(__FILE__)}/../../public/fonts/AvenirLTStd-Black.otf")
    text.annotate(canvas_es, 0, 0, x_start + dimensions.width, y_start + 90, "#{code_es} ")

    text.font = File.expand_path("#{File.dirname(__FILE__)}/../../public/fonts/AvenirLTStd-Medium.otf")
    x_width = dimensions.width + text.get_type_metrics("#{code_es} ").width
    text.annotate(canvas_es, 0, 0, x_start + x_width, y_start + 90, "al ")

    text.font = File.expand_path("#{File.dirname(__FILE__)}/../../public/fonts/AvenirLTStd-Black.otf")
    text.annotate(canvas_es, 0, 0, x_start, y_start + 180, "(203)-202-3505")

    # 597 x 553
    # text.font = File.expand_path("#{File.dirname(__FILE__)}/../../public/fonts/AvenirLTStd-Black.otf")
    text.annotate(canvas_es, 0, 0, 1220, 1596, code_es)


    # then the upper title...
    # 208, 737
    # text.font = File.expand_path("#{File.dirname(__FILE__)}/../../public/fonts/AvenirLTStd-Black.otf")

    text.pointsize = 120
    text.annotate(canvas_es, 0, 0, 208, 717, "de parte de #{teacher}.")

    # 208, 875
    text.pointsize = 45
    text.font = File.expand_path("#{File.dirname(__FILE__)}/../../public/fonts/AvenirLTStd-Medium.otf")
    dimensions = text.get_type_metrics("Obtén libros de parte de ")
    text.annotate(canvas_es, 0, 0, 208, 875, "Obtén libros de parte de ")
    text.font = File.expand_path("#{File.dirname(__FILE__)}/../../public/fonts/AvenirLTStd-Black.otf")
    text.annotate(canvas_es, 0, 0, 208 + dimensions.width, 875, "#{school} ")

    text.font = File.expand_path("#{File.dirname(__FILE__)}/../../public/fonts/AvenirLTStd-Medium.otf")
    x_width = dimensions.width + text.get_type_metrics("#{school} ").width
    text.annotate(canvas_es, 0, 0, 208 + x_width, 875, "por mensaje de text, directamente en tu celular.")

    # pdf.write("hello.pdf")
    # 350, 1242

    flyers = S3.bucket('teacher-materials')

    if flyers.exists?
        # teacher_dir = "#{teacher}-#{teacher_obj.t_number}" 
        # name = "#{school}/#{teacher_dir}/flyers/#{code_en}-flyer.png"
        # if flyers.object(name).exists?
        #     puts "#{name} already exists in the bucket"
        # else
        #   obj = flyers.object(name)
        #   obj.put(body: canvas.to_blob, acl: "public-read")
        #   puts "Uploaded '%s' to S3!" % name
        # end

        # name_es = "#{school}/#{teacher_dir}/flyers/#{code_en}-flyer-es.png"
        # if flyers.object(name_es).exists?
        #     puts "#{name_es} already exists in the bucket"
        # else
        #     obj = flyers.object(name_es)
        #     obj.put(body: canvas_es.to_blob, acl: "public-read")
        #     puts "Uploaded '%s' to S3!" % name_es
        # end

        pdf = Magick::ImageList.new
        pdf.from_blob(canvas.to_blob)

        tmpfile = File.expand_path("#{File.dirname(__FILE__)}/#{code_en}.pdf")
        pdf.write(tmpfile)
        # pdf += canvas
        name = "#{school}/#{teacher_dir}/flyers/#{code_en}-flyer.pdf"
        if flyers.object(name).exists?
            puts "#{name} already exists in the bucket"
        else
          obj = flyers.object(name)
          # obj.put(body: pdf.to_blob, acl: "public-read")
          obj.upload_file(tmpfile, acl: "public-read")
          puts "Uploaded '%s' to S3!" % name
        end

        FileUtils.rm(tmpfile)

        pdf_es = Magick::ImageList.new
        pdf_es.from_blob(canvas_es.to_blob)

        tmpfile = File.expand_path("#{File.dirname(__FILE__)}/#{code_en}-es.pdf")
        pdf_es.write(tmpfile)
        # pdf += canvas
        name = "#{school}/#{teacher_dir}/flyers/#{code_en}-flyer-es.pdf"
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

