# frozen_string_literal: true

require 'benchmark'
require 'json'
require 'faraday'
require 'typhoeus'
require 'patron'
require 'httpclient'
require 'typhoeus/adapters/faraday'
require 'excon'

stdout = File.new("single_thread_benchmark-#{Time.now.strftime('%Y%m%d%H%M')}.txt", 'w')

n = 1_000

params = {
  foo: 'bar'
}

def net_http(host)
  Faraday.new(url: host, ssl: { verify: false }) do |conn|
    conn.adapter :net_http
  end
end

def net_http_persistent(host, pool_size)
  Faraday.new(url: host, ssl: { verify: false }) do |conn|
    conn.adapter :net_http_persistent, pool_size: pool_size
  end
end

def patron(host)
  Faraday.new(url: host, ssl: { verify: false }) do |conn|
    conn.adapter :patron
  end
end

def httpclient(host)
  Faraday.new(url: host, ssl: { verify: false }) do |conn|
    conn.adapter :httpclient
  end
end

def typhoeus(host)
  Faraday.new(url: host, ssl: { verify: false }) do |conn|
    conn.adapter :typhoeus
  end
end

def excon(host)
  Faraday.new(url: host, ssl: { verify: false }) do |conn|
    conn.adapter :excon
  end
end

def post_request(client, params)
  client.post do |req|
    req.url '/rate_limit'
    req.headers['Content-Type'] = 'application/json'
    req.body = JSON.generate(params)
  end
end

Benchmark.bm(20) do |x|
  x.report('net_http:') do
    client = net_http('https://api.github.com')

    n.times do |_i|
      post_request(client, params)
    end
  end

  client = net_http_persistent('https://api.github.com', 1)
  x.report('net_http_persistent:') do
    n.times do |_i|
      post_request(client, params)
    end
  end

  x.report('patron:') do
    client = patron('https://api.github.com')

    n.times do |_i|
      post_request(client, params)
    end
  end

  x.report('httpclient:') do
    client = httpclient('https://api.github.com')

    n.times do |_i|
      post_request(client, params)
    end
  end

  x.report('typhoeus:') do
    client = typhoeus('https://api.github.com')

    n.times do |_i|
      post_request(client, params)
    end
  end

  x.report('excon:') do
    client = excon('https://api.github.com')

    n.times do |_i|
      post_request(client, params)
    end
  end
end

## user CPU time, the time spent executing your code
## system CPU time, the time spent in the kernel
## both user and system CPU time added up
## the actual time (or wall clock time) it took for the block to execute in brackets
