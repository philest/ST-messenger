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
    text.pointsize = 45 / 2

    dimensions = text.get_type_metrics(img_txt)

    x_start, x_end = 106/2, 324/2
    y_start, y_end = 290/2, 369/2

    center = {
      x: (x_start + x_end) / 2.0,
      y: (y_start + y_end) / 2.0
    }

    x = center[:x] - (dimensions.width  / 2.0)
    y = center[:y] + ((dimensions.ascent - dimensions.descent) / 2.0) - 10

    text.annotate(canvas, 106/2,290/2.0,x,y, img_txt) {
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
    text.font = File.expand_path("#{File.dirname(__FILE__)}/../../public/fonts/AvenirLTStd-Medium.otf")

    text.pointsize = 21
    x_start, x_end = 110
    y_start, y_end = 425

    dimensions = text.get_type_metrics("To start, text ")
    text.annotate(canvas, 0, 0, x_start, y_start, "To start, text ")

    text.font = File.expand_path("#{File.dirname(__FILE__)}/../../public/fonts/AvenirLTStd-Black.otf")
    img_txt_d = text.get_type_metrics("#{code_en}")
    # 406, 511
    text.annotate(canvas, 0, 0, x_start + dimensions.width, y_start, "#{code_en}")
    # text.annote
    text.font = File.expand_path("#{File.dirname(__FILE__)}/../../public/fonts/AvenirLTStd-Medium.otf")
    dimensions = text.get_type_metrics("to ")
    text.annotate(canvas, 0, 0, x_start, y_start + 28, "to ")

    text.font = File.expand_path("#{File.dirname(__FILE__)}/../../public/fonts/AvenirLTStd-Black.otf")
    text.annotate(canvas, 0, 0, x_start + dimensions.width, y_start + 28, "(203)-202-3505")



    # 597 x 553
    # text.font = File.expand_path("#{File.dirname(__FILE__)}/../../public/fonts/AvenirLTStd-Black.otf")
    text.annotate(canvas, 0, 0, 406, 528, code_en)


    # then the upper title...
    # 200, 737
    # text.font = File.expand_path("#{File.dirname(__FILE__)}/../../public/fonts/AvenirLTStd-Black.otf")
    text.pointsize = 38
    text.annotate(canvas, 0, 0, 70, 235, "#{teacher}.")

    # 200, 875
    text.pointsize = 17
    text.font = File.expand_path("#{File.dirname(__FILE__)}/../../public/fonts/AvenirLTStd-Medium.otf")
    dimensions = text.get_type_metrics("Get books from ")
    text.annotate(canvas, 0, 0, 70, 282, "Get books from ")
    text.font = File.expand_path("#{File.dirname(__FILE__)}/../../public/fonts/AvenirLTStd-Black.otf")
    text.annotate(canvas, 0, 0, 70 + dimensions.width, 282, "#{school} ")

    text.font = File.expand_path("#{File.dirname(__FILE__)}/../../public/fonts/AvenirLTStd-Medium.otf")
    x_width = text.get_type_metrics("Get books from #{school} ").width
    if "#{school}".length > 13
        add_space = 8
    else
        add_space = 0
    end
    text.annotate(canvas, 0, 0, 70 + x_width + add_space, 282, "by text message right on your phone.")

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

    text = Magick::Draw.new
    text.font = File.expand_path("#{File.dirname(__FILE__)}/../../public/fonts/AvenirLTStd-Medium.otf")
    text.pointsize = 21
    x_start = 110
    y_start = 425

    text.annotate(canvas_es, 0, 0, x_start, y_start, "Para recibir cuentos, ")

    dimensions = text.get_type_metrics("textéa ")
    text.annotate(canvas_es, 0, 0, x_start, y_start + 28, "textéa ")
    text.font = File.expand_path("#{File.dirname(__FILE__)}/../../public/fonts/AvenirLTStd-Black.otf")
    text.annotate(canvas_es, 0, 0, x_start + dimensions.width, y_start + 28, "#{code_es} ")

    text.font = File.expand_path("#{File.dirname(__FILE__)}/../../public/fonts/AvenirLTStd-Medium.otf")
    x_width = dimensions.width + text.get_type_metrics("#{code_es} ").width
    text.annotate(canvas_es, 0, 0, x_start + x_width, y_start + 28, "al ")

    text.font = File.expand_path("#{File.dirname(__FILE__)}/../../public/fonts/AvenirLTStd-Black.otf")
    text.annotate(canvas_es, 0, 0, x_start, y_start + 56, "(203)-202-3505")

    # text.font = File.expand_path("#{File.dirname(__FILE__)}/../../public/fonts/AvenirLTStd-Black.otf")
    text.annotate(canvas_es, 0, 0, 406, 528, code_es)

    # then the upper title...
    # text.font = File.expand_path("#{File.dirname(__FILE__)}/../../public/fonts/AvenirLTStd-Black.otf")

    text.pointsize = 38
    text.annotate(canvas_es, 0, 0, 70, 235, "de parte de #{teacher}.")

    text.pointsize = 17
    text.font = File.expand_path("#{File.dirname(__FILE__)}/../../public/fonts/AvenirLTStd-Medium.otf")
    dimensions = text.get_type_metrics("Obtén libros de parte de ")
    text.annotate(canvas_es, 0, 0, 70, 282, "Obtén libros de parte de ")
    text.font = File.expand_path("#{File.dirname(__FILE__)}/../../public/fonts/AvenirLTStd-Black.otf")
    text.annotate(canvas_es, 0, 0, 70 + dimensions.width, 282, "#{school} ")

    text.font = File.expand_path("#{File.dirname(__FILE__)}/../../public/fonts/AvenirLTStd-Medium.otf")
    x_width = dimensions.width + text.get_type_metrics("#{school} ").width

    if "#{school}".length > 13
        add_space = 8
    else
        add_space = 0
    end

    text.annotate(canvas_es, 0, 0, 70 + x_width + add_space, 282, "por mensaje de text, directamente en tu celular.")

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

        teacher_dir = "#{teacher}-#{teacher_obj.t_number}"
        name = "#{school}/#{teacher_dir}/flyers/#{code_en}-flyer.pdf"
        if flyers.object(name).exists?
            puts "#{name} already exists in the bucket"
        else
          obj = flyers.object(name)
          obj.put(body: pdf.to_blob, acl: "public-read")
          obj.upload_file(tmpfile, acl: "public-read")
          puts "Uploaded '%s' to S3!" % name
        end

        FileUtils.rm(tmpfile)

        pdf_es = Magick::ImageList.new
        pdf_es.from_blob(canvas_es.to_blob)

        tmpfile = File.expand_path("#{File.dirname(__FILE__)}/#{code_en}-es.pdf")
        pdf_es.write(tmpfile)
        name = "#{school}/#{teacher_dir}/flyers/#{code_en}-flyer-es.pdf"
        if flyers.object(name).exists?
            puts "#{name} already exists in the bucket"
        else
          obj = flyers.object(name)
          obj.put(body: pdf.to_blob, acl: "public-read")
          obj.upload_file(tmpfile, acl: "public-read")
          puts "Uploaded '%s' to S3!" % name
        end

        FileUtils.rm(tmpfile)
    end

  end

end
