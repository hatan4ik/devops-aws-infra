#!/usr/bin/env ruby
# Syntax-level guard for the staged workflow files. actionlint is additionally
# run by CI; this catches malformed YAML without relying on a network install.
require "yaml"

paths = Dir.glob(".github/workflows/*.{yml,yaml}").sort
abort "no workflow files found" if paths.empty?

paths.each do |path|
  document = YAML.load_file(path)
  abort "#{path}: top-level document must be a mapping" unless document.is_a?(Hash)

  event = document["on"] || document[true]
  abort "#{path}: missing on trigger" if event.nil?
  abort "#{path}: missing name" unless document["name"].is_a?(String) && !document["name"].empty?
  abort "#{path}: missing permissions" unless document["permissions"].is_a?(Hash)
  abort "#{path}: missing jobs" unless document["jobs"].is_a?(Hash) && !document["jobs"].empty?
end

puts "PASS: #{paths.length} workflow files are valid YAML with required top-level keys"
