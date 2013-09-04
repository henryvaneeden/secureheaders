INLINE_SCRIPT_REGEX = %r{(<script([ ]*(?!src)([\w\-])+=(?<quote>[\"\'])[^\"\']+\quote)*[ ]*\/?>)(?<js_content>.*)<\/script>}
SCRIPT_HASH_CONFIG_FILE = 'config/script_hashes.yml'

namespace :secure_headers do
  task :generate_hashes do
    puts "Generating script-hash values"
    puts "=" * 20

    script_hashes = {}
    Dir.glob("app/{views,templates}/**/*.{erb,mustache}") do |filename|
      file = File.read(filename)
      hashes = []
      file.scan(INLINE_SCRIPT_REGEX) do |match|
        inline_script = match.last
        if (filename =~ /\.mustache\Z/ && inline_script =~ /\{\{.*\}\}/) || (filename =~ /\.erb\Z/ && inline_script =~ /<%.*%>/)
          puts "Looks like there's some dynamic content inside of a script tag :-/"
          puts "That pretty much means the hash value will never match."
          puts "Code: " + inline_script
          puts "=" * 20
        end

        hashes << Digest::SHA256.base64digest(match.last)
      end

      if hashes.any?
        script_hashes[filename] = hashes
      end
    end

    File.open(SCRIPT_HASH_CONFIG_FILE, 'w') do |file|
      file.write(script_hashes.to_yaml)
    end

    puts "Script hashes from " + script_hashes.keys.size.to_s + " files added to #{SCRIPT_HASH_CONFIG_FILE}"
  end
end