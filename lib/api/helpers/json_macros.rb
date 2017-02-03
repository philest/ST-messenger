# this approach was inspired by https://gist.github.com/bensie/4226520#file-macros-rb-L1
require 'multi_json'


module JSONMacros
	def json(content, pretty=false)
    return MultiJson.dump(content, pretty: pretty)
  end

  def decode_json(content, symbolize=false)
    MultiJson.load(content, symbolize_keys: symbolize)
  end

  def jsonError(code, title="DEFAULT TITLE")
    return json({code:code, title:title})
  end

  def jsonSuccess(code, title="DEFAULT TITLE")
    return json({code:code, title:title})
  end

end