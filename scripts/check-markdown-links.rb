#!/usr/bin/env ruby
# frozen_string_literal: true

# Verifies repository-relative Markdown links without reaching the network.
# Current-state documentation must stay navigable even when external references
# or private GitHub pages cannot be fetched by CI.

require "pathname"

docs_root = Pathname.new(ARGV.fetch(0, "docs")).realpath
failures = []

Dir.glob(docs_root.join("**", "*.md")).sort.each do |filename|
  in_fence = false

  File.readlines(filename, chomp: true).each_with_index do |line, index|
    in_fence = !in_fence if line.lstrip.start_with?("```")
    next if in_fence

    line.scan(/!?\[[^\]]*\]\((?:<)?([^\s)>]+)(?:>)?(?:\s+[^)]*)?\)/) do |match|
      target = match.first
      next if target.empty? || target.start_with?("#", "/")
      next if target.match?(%r{\A(?:[a-z][a-z0-9+.-]*:|//)}i)

      relative_path = target.split("#", 2).first
      next if relative_path.empty?

      resolved = Pathname.new(File.expand_path(relative_path, File.dirname(filename)))
      next if resolved.exist?

      failures << "#{filename}:#{index + 1}: missing local link #{target}"
    end
  end
end

if failures.empty?
  puts "Markdown local links: OK"
  exit 0
end

warn failures.join("\n")
exit 1
