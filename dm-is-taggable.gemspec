# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{dm-is-taggable}
  s.version = "0.1.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Aaron Qian, Maxime Guilbot"]
  s.date = %q{2009-05-09}
  s.description = %q{Tagging implementation for DataMapper}
  s.email = ["team [a] ekohe [d] com"]
  s.extra_rdoc_files = ["README.textile", "LICENSE", "TODO"]
  s.files = ["History.txt", "LICENSE", "Manifest.txt", "README.textile", "Rakefile", "TODO", "lib/dm-is-taggable.rb", "lib/dm-is-taggable/aggregate_patch.rb", "lib/dm-is-taggable/do_adapter_ext.rb", "lib/dm-is-taggable/tag.rb", "lib/dm-is-taggable/tagging.rb", "lib/dm-is-taggable/tag_list.rb", "lib/dm-is-taggable/is/taggable.rb", "lib/dm-is-taggable/is/version.rb", "lib/dm-is-taggable/is/shared.rb", "lib/dm-is-taggable/is/tag.rb", "lib/dm-is-taggable/is/tagging.rb", "lib/dm-is-taggable/is/tagger.rb", "spec/integration/taggable_spec.rb", "spec/integration/tagger_similarity_spec.rb", "spec/data/article.rb", "spec/data/picture.rb", "spec/data/bot.rb", "spec/data/user.rb", "spec/spec.opts", "spec/spec_helper.rb"]
  s.homepage = %q{http://github.com/aq1018/dm-is-taggable}
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{dm-is-taggable}
  s.rubygems_version = %q{1.3.2}
  s.summary = %q{Tagging implementation for DataMapper}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<dm-core>, [">= 0.9.6"])
      s.add_runtime_dependency(%q<dm-aggregates>, [">= 0.9.6"])
      s.add_development_dependency(%q<hoe>, [">= 1.12.1"])
    else
      s.add_dependency(%q<dm-core>, [">= 0.9.6"])
      s.add_dependency(%q<dm-aggregates>, [">= 0.9.6"])
      s.add_dependency(%q<hoe>, [">= 1.12.1"])
    end
  else
    s.add_dependency(%q<dm-core>, [">= 0.9.6"])
    s.add_dependency(%q<dm-aggregates>, [">= 0.9.6"])
    s.add_dependency(%q<hoe>, [">= 1.12.1"])
  end
end
