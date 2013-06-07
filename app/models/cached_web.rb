class CachedWeb
  
  @@min_wait_times = {}
  @@last_request_times = {}
 
  def escape_key(key)
    if key.size > 140
      Digest::MD5.hexdigest(key)
    else
      key.gsub(/[^a-z0-9]/i,"_")
    end
  end
  
  def self.get(params)
    CachedWeb.new.get(params)
  end
  
  def get(params)
    url = params[:url].gsub(" ","%20").gsub("%off", "%25off")
    page, redirect_url, headers = get_cache(:url=>url, :expires_in=>params[:expires_in], :details=>true) rescue [nil, nil, nil]
    
    if params[:cache_only]
      return [nil, nil, nil] if page.blank?
      return [page, redirect_url, headers]
    end

    if page.blank?
      uri = URI.parse(url)
      domain = uri.host.downcase
      #puts "Not in cache - getting: #{params[:url]}"
      # Don't hit a site more than once per 5 seconds
      time_to_wait = (@@min_wait_times[domain] || 5) -
        (Time.now - (@@last_request_times[domain] || Time.at(0)))

      puts "#{Time.now} - (#{@@last_request_times[domain]}) = #{ (Time.now - (@@last_request_times[domain])) }"

      if time_to_wait > 0  
        puts "Waiting for #{time_to_wait} on domain #{domain}"
        sleep time_to_wait
      end
      
      @agent = Mechanize.new unless @agent
      page = @agent.get(url) 
      @@last_request_times[domain] = Time.now
      content = page.body
      redirect_url = page.uri.to_s
      headers = page.header
      set_cache(:url=>url, :redirect_url=>redirect_url, :headers=>headers, :content=>content)
      [content, redirect_url, headers]
    else
      [page, redirect_url, headers]
    end
  end

  def self.fetch_cache(params, &block)
    CachedWeb.new.fetch_cache(params, &block)
  end

  def fetch_cache(params)
    ret_val = nil
    begin
      ret_val = get_cache(params)
    rescue
      puts "didn't find data in cache: #{$!}"
    end
    unless ret_val
      ret_val = yield self
      set_cache(params.merge(:content=>ret_val))
    end
    
    return ret_val
  end
  
  def post(url, params)
    puts "Not in cache - POSTing to: #{url}"
    @agent = Mechanize.new unless @agent
    begin
      page = @agent.post(url, params)
      uri = URI.parse(url)
      @@last_request_times[uri.host]
      content = page.body
      redirect_url = page.uri.to_s
      headers = page.header
      set_cache(:url=>url, :redirect_url=>redirect_url, :headers=>headers, :content=>content)
      [content, redirect_url, headers]
    rescue Exception => e
      puts e
      puts e.backtrace
      Toadhopper(AIRBRAKE_KEY).post!(e)
      ["", url, {}]
    end
  end

  def set_cache(params)
    key = escape_key(params[:url].present? ? params[:url] : params[:key])
    content = params[:content]
    redirect_url = params[:redirect_url]
  
    h = {:content => content, :redirect_url=>redirect_url}
  
  
    path = "/tmp/cachedweb/#{key}"
    #puts "Saving file to #{path}"
    begin
      File.open(path, 'w') do |out|
         YAML.dump(h, out)
      end
    rescue Exception
      `mkdir -p /tmp/cachedweb`
      File.open(path, 'w') do |out|
         YAML.dump(h, out)
      end
    end
    true
  end
  
  def get_cache(params)
    key = escape_key(params[:url].present? ? params[:url] : params[:key])
    details = params[:details]
    expires_in = params[:expires_in]
  
    timestamp = nil

    path = "/tmp/cachedweb/#{key}"
    timestamp = File.ctime(path)

    if expires_in and timestamp.nil?
      #puts "There is no timestamp, force a get of this URL so we can add a timestamp"
      throw "There is no timestamp, force a get of this URL so we can add a timestamp"
    end
  
    if expires_in and timestamp and timestamp < (Time.now - expires_in)
      #puts "Cache is older than desired, saved on #{timestamp}"
      throw "Cache is older than desired, saved on #{timestamp}"
    end
  
    h = YAML::load_file(path)
    content = h[:content]
    redirect_url = h[:redirect_url]
    if details
      [content, redirect_url, nil]
    else
      content
    end
  end

end
