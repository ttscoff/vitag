#!/usr/bin/env ruby
require 'pp'
require 'shellwords'
require 'optparse'
require 'zlib'

module Tagger

  class TagHash < Hash

    def add_tags(new_tags)
      tags = self
      new_tags = [new_tags] unless new_tags.is_a? Array
      new_tags.each do |tag|
        if tags.key?(tag)
          tags[tag] += 1
        else
          tags[tag] = 1
        end
      end
      tags
    end

    def apply_min(min)
      select {|t,c| c >= min}
    end

    def max_value
      group_by {|k,v| v }.max.last[0][1]
    end

    # write a list of tags found to a file
    # @argument file (String, required) target file
    # options
    #   :counts     => (Boolean, optional) include the number of occurrences for each tag in the output
    #   :min_count  => (Integer, optional) minimum number of tag occurrences required to be included
    def write_to(file,opt={})
      raise "Output file not found" unless file && File.exists?(File.dirname(File.expand_path(file)))
      # raise "No content provided" unless opt[:content] && opt[:content].strip.length > 0
      opt[:color] ||= false
      opt[:counts] ||= false
      opt[:min_count] ||= -1

      # file ||= File.expand_path("~/" + "all_tags" + (opt[:min_count] && opt[:min_count] > 0 ? "_" + opt[:min_count].to_s : "") + ".txt")

      File.open(File.expand_path(file),'w') do |f|
        f.puts self.to_s(opt)
      end
    end

    def to_s(opt={})
      tagset = self
      opt[:sort] ||= 'count'
      opt[:order] ||= 'asc'
      opt[:color] ||= false
      opt[:counts] ||= false

      colors = {
        :default => "\033[0;39m",
        :black => "\033[0;30m",
        :red => "\033[0;31m",
        :green => "\033[0;32m",
        :brown => "\033[0;33m",
        :blue => "\033[0;34m",
        :purple => "\033[0;35m",
        :cyan => "\033[0;36m",
        :light_grey => "\033[0;37m",
        :dark_grey => "\033[1;30m",
        :light_red => "\033[1;31m",
        :light_green => "\033[1;32m",
        :yellow => "\033[1;33m",
        :light_blue => "\033[1;34m",
        :light_purple => "\033[1;35m",
        :light_cyan => "\033[1;36m",
        :white => "\033[1;37m"
      }
      ret_value = ""
      max_count = tagset.max_value
      inc = max_count / 4
      sm_inc = (inc / 3).to_i
      tags = tagset.sort_by{|k,v| opt[:sort] == 'count' ? v : k }
      tags.reverse! if opt[:order] == 'desc'
      tags.each {|tag|
        if opt[:color]
          color = case tag[1]
            when 0..(sm_inc/2) then colors[:dark_grey]
            when ((sm_inc/2)+1)..sm_inc then colors[:white]
            when sm_inc+1..(sm_inc*2) then colors[:light_cyan]
            when ((sm_inc*2)+1)..inc then colors[:green]
            when (inc+1)..(inc*2) then colors[:blue]
            when ((inc*2)+1)..(inc*3) then colors[:yellow]
            when ((inc*3)+1)..((inc*4)+10) then colors[:red]
            else colors[:default]
          end
        else
          color = ""
        end
        ret_value += "#{color}#{tag[0]}#{colors[:default]}"
        ret_value += " [#{color}#{tag[1]}#{colors[:default]}]" if opt[:counts]
        ret_value += "\n"
      }
      ret_value
    end
  end


  class SystemTags
    attr_writer :onlyin, :min_count
    attr_accessor :tags

    def initialize(options={})
      # if options[:cachefile]
      #   @cachefile = File.expand_path(options[:cachefile])
      # else
      #   @cachefile = File.expand_path("~/.tag_cache")
      # end

      # @cache = load_cache(@cachefile)

      @onlyin = options[:onlyin].nil? ? ["~"] : options[:onlyin]
      @termwidth = `tput cols`.strip.to_i - 4

      if options[:min_count].nil?
        @min_count = -1
      else
        @min_count = options[:min_count].to_s =~ /(false|no)/ ? -1 : options[:min_count].to_i
      end
    end

    # def cache(obj, cachefile="~/.tag_cache")
    #   marshal_dump = Marshal.dump(obj)
    #   File.open(File.expand_path(cachefile),'w') do |f|
    #     f.write marshal_dump
    #   end
    # end

    # def load_cache(cachefile="~/.tag_cache")
    #   if File.exists?(File.expand_path(cachefile))
    #     obj = Marshal.load IO.read(File.expand_path(cachefile))
    #   else
    #     obj = {:tags => TagHash.new, :files => []}
    #   end
    #   obj
    # end

    def update
      @tags = gather
    end

    private

    def update_stderr(str,newline=false)

      $stderr.print "\r\033[0K#{str[0..@termwidth]}"
      $stderr.print "\n" if newline
    end

    def gather

      tags = TagHash.new

      unless @onlyin.is_a? Array
        @onlyin = @onlyin.split(/\s*,\s*/)
      end
      if @onlyin.length > 0
        onlyin_string = @onlyin.map{|o| "-onlyin '#{File.expand_path(o.strip)}'"}.join(" ")
      else
        onlyin_string = ""
      end
      update_stderr("Gathering tags from #{@onlyin.join(', ')}",true)
      files = %x{mdfind #{onlyin_string} -attr kMDItemUserTags 'kMDItemUserTags == "*"'}

      files.gsub!(/(?mi)(\/[\s\S]*?) kMDItemUserTags = \(([\s\S]*?)\)/) do |m|
        match = Regexp.last_match
        update_stderr("Parsing: #{match[1]}")

        new_tags = match[2].split(/\n/).map {|m| m.strip.gsub(/,/,'').gsub(/["\\]/,'').strip }.delete_if {|m| m.strip =~  /^$/ }
        tags.add_tags(new_tags)
        # @cache = cache(match[1],tags)
      end

      @tags = tags.apply_min(@min_count) if @min_count > 0
      tags || {}
    end
  end
end

# stags = Tagger::SystemTags.new({:onlyin => ['~/Desktop','~/Dropbox'], :min_count => 1})
# stags.update
# puts stags.tags.to_s({:color => true, :counts => true, :sort => 'count', :order => 'asc', :min_count => 2 })
# stags.tags.write_to("~/Desktop/testtags.txt")
