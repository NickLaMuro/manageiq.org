require "active_support/core_ext/string/inflections"

module Miq
  class GuidesMenu < Executor
    def self.build
      new.build
    end

    def self.build_doc_menu_html
      new.build_doc_menu_html
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

    MENU_TEMPLATE = <<~MENU_TEMPLATE
      {% assign hpath = page.url | append: ".html" %}
      {% assign rpath = page.url | remove: "/index" %}

      <ul class="menu menu-toplevel" id="guides_menu">
      <% parent_items.each do |group| -%>
        <li class="menu-parent {% if "<%= group["path"] %>" == page.url or "<%= group["path"] %>" == hpath %} active menu-open{% endif %}">
          <%= render_menu_link_for group %>
          <% if group["children"] && group["children"].size > 0 %>
          <%= render_children group.children %>
          <% end -%>
        </li>
      <% end -%>
      <% solo_items.each do |group| -%>
        <li{% if "<%= group["path"] %>" == page.url or "<%= group["path"] %>" == hpath %} class="active menu-open"{% endif %}>
          <%= render_menu_link_for group %>
        </li>
      <% end -%>
      </ul>
    MENU_TEMPLATE

    # TODO:  Either combine with `#build`, or delete the code for that
    def build_doc_menu_html
      menu_items   = site.data["menus"]["guides_menu"]["children"]
      parent_items = menu_items.select {|e| e["children"] }
      solo_items   = menu_items.reject {|e| e["children"] }
    end

    private

    def render_menu_link_for item
      %(<a href="#{item["path"] || "#"}">#{group["title"]}</a>)
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
