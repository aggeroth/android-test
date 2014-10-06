require 'fileutils'
require 'yaml'
require 'open-uri'
require 'json'
@conf = YAML.load_file("config/project_settings.yml")
@testdata = YAML.load_file("config/test_settings.yml")
@environment = ENV['environment'] ? ENV['environment'] : @testdata['test']['environment']

# rake helper functions for android tasks
namespace :android do
  include FileUtils
  def apks
    @apks ||= Dir[@conf['project']['build_dir'] + "/*.apk"]
    if @apks.empty?
      puts "ERROR: No APK's found in #{@conf['project']['build_dir']} ..aborting"
      exit 1
    end
    @apks
  end

  def default_apk
    @default_apk ||= apks.find { |apk_name| apk_name.include? @environment }
  end

  def generate_directories
    if File.directory?(@conf['project']['build_dir'])
      `rm -rf #{@conf['project']['build_dir']}`
    end
    mkdir @conf['project']['build_dir']
  end

  def download_apk(params = {})
    operation_type = 'wget'
    if ENV['endpoint_type'] == 'local'
      operation_type = 'cp -rf'
    end
    if ENV['endpoint_download']
      path = ENV['endpoint_download']
    else
      path = @conf['remote']['endpoint_download']
    end
    if params[:buildnumber]
      puts "Using specified build number #{params[:buildnumber]}"
      path = @conf['remote']['endpoint_download_build']
      path = path.gsub('BUILDNUM',params[:buildnumber])
    end
    
    if !ENV['username'] && !ENV['password']
      puts "Please provide your username & password for teamcity e.g. rake android:setup username=AlexJones password=ThisisMyPassword"
      exit 
    else
      puts "Using #{ENV['username']} and #{ENV['password']}"
    end
    
    path = path.gsub("UNAME",ENV['username'])
    path = path.gsub("PWORD",ENV['password'])
    puts "Operation type #{operation_type} on path #{path}"

    `#{operation_type} #{path} -P #{@conf['project']['build_dir']}`
    if ENV['endpoint_payload']
      payload = ENV['endpoint_payload']
    else
      payload = @conf['remote']['endpoint_payload']
    end
    Dir.chdir(@conf['project']['build_dir']) {
      `unzip #{payload} 2>/dev/null`
      `mv apk/*.apk . 2>/dev/null`
    }
  end

  def resign_apk(apk_file)
    if File.directory?('test_servers')
      `rm -rf test_servers`
    end
    `calabash-android resign #{apk_file}`
  end

  def display_installed_apk
    puts `adb shell pm list packages | grep blinkbox`
  end
end

#android rake tasks
namespace :android do
  desc "Get latest android APK"
  task :get_latest_apk do
    generate_directories
    download_apk
    puts default_apk
  end

  desc "builds and resigns the apk"
  task :resign, [:apk_file] do |_, args|
    apk_file = args[:apk_file] || default_apk
    resign_apk(apk_file)
  end

  desc "Installs the apk and test server (will reinstall if installed)"
  task :install_apk, [:apk_file] do |_, args|
    apk_file = args[:apk_file] || default_apk
    `adb install -r #{apk_file}`
  end
  desc "Gets the latest apk, resigns it and installs the apk, optional argument for a specified build"
  task :setup, [:buildnumber] do |_, args|
    buildn = args[:buildnumber]
    if buildn
      puts buildn
      generate_directories
      download_apk(:buildnumber => buildn)
      puts default_apk 
    else
      Rake::Task["android:get_latest_apk"].invoke
    end
    Rake::Task["android:resign"].invoke
    Rake::Task["android:install_apk"].invoke
  end
  desc "Displays installed blinkbox APK's on device (Requires connected device)"
  task :display_installed_apk do
    display_installed_apk
  end
end

#calabash rake tasks
namespace :calabash do
  desc "Prints out details about current configuration"
  task :run_config do
    puts "Tests are currently to run on #{@testdata['test']['device']} under #{@testdata['test']['environment']} configuration"
  end

  desc "Checks development environment and install essentials"
  task :environment_install do
    system("./config/dev_env_install")
  end

  desc 'Run calabash-android console with included Calabash::Android::Operations, as well as android-test support modules & page models'
  task :console, [:apk_file] do |_, args|
    apk_file = args[:apk_file] || default_apk
    ENV['IRBRC'] = File.join(File.dirname(__FILE__), 'irbrc')
    puts "REMEMBER: to run 'rake android:resign[#{apk_file}]', if you have issues running this APK"
    system "calabash-android console #{apk_file}"
  end

  desc "Runs calabash android"
  task :run, [:apk_file] do |_, args|
    apk_file = args[:apk_file] || default_apk
    puts "Running with environment:#{@environment}"
    puts "REMEMBER: to run 'rake android:resign[#{apk_file}]', if you have issues running this APK"
    formatter = ENV['formatter'] ? ENV['formatter'] : "LoggedFormatter"
    output_path = ENV['output'] ? ENV['output'] : ""
    puts "Using formatter #{formatter}"

    if ENV["feature"]
      puts "RUNNING: feature=#{ENV["feature"]}"
      output = `calabash-android run #{apk_file} #{ENV["feature"]} -f #{formatter} -o #{output_path} -f pretty`
    elsif ENV["profile"]
      output = `calabash-android run #{apk_file} --profile=#{ENV['profile']} -f #{formatter} -o #{output_path}`
    else
      output = `calabash-android run #{apk_file}`
    end
    puts output
  end

  desc "Runs calabash android with given profile"
  task :run_with_profile, [:profile, :apk_file] do |t, args|
    profile = args[:profile] || 'default'
    apk_file = args[:apk_file] || default_apk
    puts "REMEMBER: to run 'rake android:resign[#{apk_file}]', if you have issues running this APK"

    system("calabash-android run #{apk_file} -p #{profile}")
  end
end

task :default do
  #endpoint_download=custom endpoint
  #endpoint_payload=customise what is being downloaded e.g. 'apk.zip', 'apk.tar.gz'
  #configuration=custom configuration
end
