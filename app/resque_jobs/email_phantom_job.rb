# This background job is responsible for emailing a PDF version of a figure.
module EmailPhantomJob
  @queue = :pdf_email

  # Options for Shrimp (https://github.com/adjust/shrimp) the logfile is a custom option added in a fork
  # here: https://github.com/benrudolph/shrimp
  @options = {
    :viewport_width => 896,
    :viewport_height => 1270,
    :margin => '0cm',
    :rendering_time => 40000,
    :logfile => 'log/pdf.log'
  }

  # The folder where the PDFs will be stored
  @output = "#{Rails.root}/public/reports/pdf"

  # @param url - the url that Shrimp should use to convert to a PDF
  # @param cookies - the cookies that are set for the user. this is important for auth reasons
  # @param name - the name of the pdf
  # @param to - the email address to send to
  def self.perform(url, cookies, name, to)
    filename = "#{name.strip.tr(' ', '_')}-#{Time.now.to_i}.pdf"
    path = "#{@output}/#{filename}"
    p = Shrimp::Phantom.new(url, @options, cookies)
    fullpath = p.to_pdf(path)

    Pony.mail(:to => to,
              :from => 'axis@unhcr.org',
              :subject => name,
              :body => Quoth.get,
              :attachments => { filename => File.read(fullpath) },
              :via => :smtp,
              :via_options => {
                :address => 'smtphub.unhcr.local',
                :port => 25,
                :user_name => 'hqaxis',
                :password => ENV['EMAIL_PASSWORD'],
                :authentication => :ntlm,
                :openssl_verify_mode => 'none',
              })
  end
end
