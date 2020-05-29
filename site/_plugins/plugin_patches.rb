require 'set'
require 'jemoji'
require 'pathname'
require 'liquid'

puts
puts
puts "PATCHING!!!!"
puts
puts


SIMPLE_EMOJI_FILTER = /:([a-zA-Z0-9\+\-]+):/.freeze

module Jekyll
  class Emoji
    def self.emoji_map
      @emoji_map ||= HTML::Pipeline::EmojiFilter.emoji_names.map {|e| ":#{e}:" }
    end

    def self.emojify(doc)
      return if (possible_emoji = doc.output.scan(::SIMPLE_EMOJI_FILTER)).empty?
      return if (possible_emoji & emoji_map).empty?

      src = emoji_src(doc.site.config)
      if doc.output.include? BODY_START_TAG
        parsed_doc    = Nokogiri::HTML::Document.parse(doc.output)
        body          = parsed_doc.at_css('body')
        body.children = filter_with_emoji(src).call(body.inner_html)[:output].to_s
        doc.output    = parsed_doc.to_html
      else
        doc.output = filter_with_emoji(src).call(doc.output)[:output].to_s
      end
    end
  end
end

module LiquidExpressionCache
  def self.expression_cache
    @expression_cache ||= {}
  end

  def parse(markup)
    ::LiquidExpressionCache.expression_cache[markup] ||= super
  end
end

module Liquid
  class Expression
    class << self
      prepend LiquidExpressionCache
    end
    # def self.parse(markup)
    #   if LITERALS.key?(markup)
    #     LITERALS[markup]
    #   else
    #     case markup
    #     when SINGLE_QUOTED_STRING, DOUBLE_QUOTED_STRING
    #       $1
    #     when INTEGERS_REGEX
    #       $1.to_i
    #     when RANGES_REGEX
    #       RangeLookup.parse($1, $2)
    #     when FLOATS_REGEX
    #       $1.to_f
    #     else
    #       VariableLookup.parse(markup)
    #     end
    #   end
    # end
  end
end


# class Pathname
#   CHOP_BASENAME_MAP = (SEPARATOR_LIST.chars << "").map { |c| [c, true] }.to_h.freeze

#   def chop_basename(path) # :nodoc:
#     base = File.basename(path)
#     if CHOP_BASENAME_MAP[base]
#       return nil
#     else
#       return path[0, path.rindex(base)], base
#     end
#   end
#   private :chop_basename
# end
