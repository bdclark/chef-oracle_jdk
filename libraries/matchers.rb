if defined?(ChefSpec)
  def install_oracle_jdk(res_name)
    ChefSpec::Matchers::ResourceMatcher.new(:oracle_jdk, :install, res_name)
  end

  def remove_oracle_jdk(res_name)
    ChefSpec::Matchers::ResourceMatcher.new(:oracle_jdk, :remove, res_name)
  end
end
