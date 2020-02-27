require "active_support/core_ext/string/inflections"

module Miq
  class GuidesMenu < Executor
    def self.build
      new.build
    end

    def self.build_dev_menu_html
      new.build_dev_menu_html
    end

    def self.build_api_menu_html
      new.build_api_menu_html
    end

    attr_reader :source_dir, :output_dir

    def initialize(transform_paths: true)
      @source_dir = Pathname.new(ENV["MIQ_GUIDES_DST"] || Miq.docs_dir.join("guides"))
      @output_dir = Miq.working_dir.join("tmp", "menus")
      @transform_paths = transform_paths
    end

    def menu_data
      @data ||= walk_tree(source_dir)
    end

    def to_yaml
      menu_data.to_yaml
    end

    def build
      prep(output_dir)

      File.open("#{output_dir}/guides_menu.yml", "w") do |f|
        f.puts to_yaml
      end
    end

    MENU_TEMPLATE = ERB.new <<~MENU_TEMPLATE, :trim_mode => "-"
      {% assign hpath = page.url | append: ".html" %}
      {% assign rpath = page.url | remove: "/index" %}

      <ul class="menu menu-toplevel" id="guides_menu">
      <% parent_items.each do |item| -%>
        <li class="menu-parent {% <%= liquid_if item, true %> %} active menu-open{% endif %}">
          <%= render_menu_link_for item %>
          <%= render_children item["children"] %>
        </li>
      <% end -%>
      <% solo_items.each do |item| -%>
        <%= render_solo_item_for item, true %>
      <% end -%>
      </ul>
    MENU_TEMPLATE

    # TODO:  Either combine with `#build`, or delete the code for that
    def build_dev_menu_html
      # menu_items               = site.data["menus"]["guides_menu"]["children"]
      menu_file                = Miq.working_dir.join("site", "_data", "menus", "guides_menu.yml")
      menu_items               = YAML.load_file(menu_file)["children"]
      parent_items, solo_items = partion_by_children(menu_items)
      MENU_TEMPLATE.result(binding)
    end

    API_TEMPLATE = ERB.new <<~API_TEMPLATE, :trim_mode => "-"
      {% assign hpath = page.url | append: ".html" %}
      {% assign rpath = page.url | remove: "/index" %}

      <ul class="menu menu-toplevel" id="api_menu">
      <% parent_items.each do |item| -%>
        <li class="menu-item menu-parent {% <%= liquid_if item, true, true %> %} active{% endif %}">
          <%= render_menu_link_for item %>
          <%= render_children item["children"] %>
        </li>
      <% end -%>
      <% solo_items.each do |item| -%>
        <li class="menu-item {% <%= liquid_if(item, true, true) %> %} active{% endif %}">
          <%= render_menu_link_for item %>
        </li>
      <% end -%>
      </ul>
    API_TEMPLATE

    def build_api_menu_html
      menu_file                = Miq.working_dir.join("site", "_data", "menus", "api_menu.yml")
      menu_items               = YAML.load_file(menu_file)
      parent_items, solo_items = partion_by_children(menu_items)
      API_TEMPLATE.result(binding)
    end

    private

    def partion_by_children items
      items.partition {|e| e["children"] && e["children"].size > 0 }
    end

    CHILDREN_TEMPLATE = ERB.new <<~CHILDREN_TEMPLATE, :trim_mode => "-"
      <ul>
        <% parent_items.each do |item| -%>
        <li class="doc-menu-item {% <%= liquid_if item, false %> %} active{% endif %}">
          <%= render_menu_link_for(item) %>
          <%= render_children item["children"] %>
        </li>
        <% end -%>
        <% solo_items.each do |item| -%>
          <%= render_solo_item_for item %>
        <% end -%>
      <ul>
    CHILDREN_TEMPLATE
    def render_children(children)
      if children and children.size > 0
        parent_items, solo_items = partion_by_children(children)
        CHILDREN_TEMPLATE.result(binding)
      else
        ""
      end
    end

    def render_menu_link_for(item)
      %(<a href="#{item["path"] || "#"}">#{item["title"]}</a>)
    end

    def render_solo_item_for(item, top_level = false)
      active_class  = "active"
      active_class << " menu-open" if top_level

      if top_level
        <<~DATA
          <li{% #{liquid_if(item, top_level)} %} class="#{active_class}"{% endif %}>
            #{render_menu_link_for(item)}
          </li>
        DATA
      else
        <<~DATA
          <li class="doc-menu-item {% #{liquid_if(item, top_level)} %} #{active_class}{% endif %}">
            #{render_menu_link_for(item)}
          </li>
        DATA
      end
    end

    def liquid_if item, top_level = false, api = false
      lif  = %(if "#{item["path"]}" == page.url)
      lif << %( or "#{item["path"]}" == hpath) unless api
      lif << %( or "#{item["path"]}" == rpath) unless top_level or api
      lif
    end

    def walk_tree(path, title = nil)
      title = title || File.basename(path)
      human_title = title.humanize.titlecase

      data = { "title" => human_title }

      # When a file exists one level up with the same name as a directory,
      # assign the path of that file to this point in the tree.
      # Also link with extension to avoid generated directory listing page.
      parent_path = path.to_s.split("/")[0..-2].join("/")
      if same_name = Dir.entries(parent_path).detect {|e| e =~ /#{title}\.md/ }
        data["path"] = replace_path(File.join(parent_path, same_name), '.html')
      end

      # Collect children beneath this level
      data["children"] = []
      entries = filtered_entries(path)

      # If we have a directory and file sharing a name,
      # filter out the file since we already assigned the path above.
      # First, separate files and directories
      directories = []
      files = []
      entries.each do |e|
        if File.directory?(File.join(path, e))
          directories << e
        else
          files << e
        end
      end

      files.reject! {|f| directories.include?(f.sub(".md","")) }

      # Put everything back together
      directories.each do |dir|
        full_path = File.join(path, dir)
        data["children"] << walk_tree(full_path, dir)
      end

      files.each do |f|
        full_path = File.join(path, f)
        data["children"] << build_child(f, full_path)
      end

      data
    end

    def filtered_entries(path)
      Dir.entries(path).keep_if do |child|
        next if exclusions.include?(child)

        File.directory?(File.join(path, child)) ||
        inclusions.include?(File.extname(child))
      end
    end

    def build_child(name, path)
      {
        "title" => titlefy(name),
        "path" => replace_path(path)
      }
    end

    def transform(path)
      if transform_paths?
        Miq.md_file_to_html(path)
      else
        path
      end
    end

    def replace_path(path, replacement = '')
      path.gsub(/#{Miq.site_dir}/, '').gsub(".md", replacement)
    end

    def titlefy(path)
      path.gsub(/(\.md|\.html)$/i, '').humanize.titlecase
    end

    def transform_paths?
      !!(@transform_paths)
    end

    def exclusions
      ["..", "."]
    end

    def inclusions
      [".md"]
    end
  end
end
