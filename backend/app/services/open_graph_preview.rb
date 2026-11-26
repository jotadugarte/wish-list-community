# frozen_string_literal: true

require "net/http"
require "ipaddr"
require "timeout"

# Synchronous best-effort og:title / og:image extract with SSRF protections.
# Traceability: [REQ-ITEM-006]
class OpenGraphPreview
  TIMEOUT_SECONDS = 4
  MAX_BYTES = 512_000
  MAX_REDIRECTS = 3
  BLOCKED_NETWORKS = [
    IPAddr.new("0.0.0.0/8"),
    IPAddr.new("10.0.0.0/8"),
    IPAddr.new("127.0.0.0/8"),
    IPAddr.new("169.254.0.0/16"),
    IPAddr.new("172.16.0.0/12"),
    IPAddr.new("192.168.0.0/16"),
    IPAddr.new("::1/128"),
    IPAddr.new("fc00::/7"),
    IPAddr.new("fe80::/10")
  ].freeze

  # [REQ-ITEM-006] Returns hash with :title, :image_url, :source_url (strings, possibly empty).
  def self.fetch(raw_url)
    new(raw_url).fetch
  end

  def initialize(raw_url)
    @url_vo = ExternalUrl.new(raw_url)
  end

  # [REQ-ITEM-006] SSRF-safe download of a remote image URL (bytes) or nil.
  def self.download_bytes(raw_url)
    new(raw_url).download_bytes
  end

  # [REQ-ITEM-006] Downloads response body with the same SSRF/timeout rules as HTML fetch.
  def download_bytes
    download_html(@url_vo.uri)
  rescue ArgumentError
    nil
  end

  # [REQ-ITEM-006] Best-effort; never raises for remote failures — returns empty fields.
  def fetch
    html = download_html(@url_vo.uri)
    return empty_result if html.nil?

    {
      title: extract_meta(html, "og:title").to_s,
      image_url: extract_meta(html, "og:image").to_s,
      source_url: @url_vo.value
    }
  rescue ArgumentError
    empty_result
  end

  private

  def empty_result
    { title: "", image_url: "", source_url: @url_vo.value }
  end

  def download_html(uri, redirects = 0)
    raise ArgumentError, "too many redirects" if redirects > MAX_REDIRECTS

    assert_public_http_uri!(uri)
    response = nil
    Timeout.timeout(TIMEOUT_SECONDS) do
      Net::HTTP.start(
        uri.host,
        uri.port,
        use_ssl: uri.scheme == "https",
        open_timeout: TIMEOUT_SECONDS,
        read_timeout: TIMEOUT_SECONDS,
        ipaddr: resolve_public_ip!(uri.host)
      ) do |http|
        request = Net::HTTP::Get.new(uri)
        request["User-Agent"] = "WishListCommunityBot/1.0"
        response = http.request(request)
      end
    end

    case response
    when Net::HTTPRedirection
      location = response["location"].to_s
      return nil if location.empty?

      download_html(ExternalUrl.new(absolute_redirect(uri, location)).uri, redirects + 1)
    when Net::HTTPSuccess
      body = response.body.to_s.byteslice(0, MAX_BYTES)
      body
    else
      nil
    end
  rescue Timeout::Error, SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, OpenSSL::SSL::SSLError
    nil
  end

  def absolute_redirect(base, location)
    URI.join(base.to_s, location).to_s
  end

  def assert_public_http_uri!(uri)
    ExternalUrl.new(uri.to_s)
    raise ArgumentError, "SSRF blocked: userinfo not allowed" if uri.userinfo
  end

  def resolve_public_ip!(host)
    addrs = Addrinfo.getaddrinfo(host, nil, nil, :STREAM).first(8)
    raise ArgumentError, "SSRF blocked: no address" if addrs.empty?

    ip = IPAddr.new(addrs.first.ip_address)
    raise ArgumentError, "SSRF blocked: private address" if blocked_ip?(ip)

    ip.to_s
  end

  def blocked_ip?(ip)
    candidates = [ ip ]
    # Normalize IPv4-mapped IPv6 (e.g. ::ffff:127.0.0.1) to the embedded IPv4.
    if ip.ipv6? && ip.ipv4_mapped?
      candidates << ip.native
    end
    candidates.any? { |addr| BLOCKED_NETWORKS.any? { |net| net.include?(addr) } }
  end

  def extract_meta(html, property)
    pattern = /<meta[^>]+property=["']#{Regexp.escape(property)}["'][^>]+content=["']([^"']+)["'][^>]*>/i
    match = html.match(pattern)
    return match[1].to_s.strip if match

    pattern2 = /<meta[^>]+content=["']([^"']+)["'][^>]+property=["']#{Regexp.escape(property)}["'][^>]*>/i
    match2 = html.match(pattern2)
    match2 ? match2[1].to_s.strip : ""
  end
end
