require File.expand_path './constants.rb'
require File.expand_path './reader.rb'

class Bandejao
	attr_accessor :pdf_file

	def initialize(pdf)
		@pdf_file = pdf
		@last_download = Time.new 0
	end

	def zero_pad(str)
		if str.length == 1
			'0' + str
		else
			str
		end
	end

	def escape_md(text)
		text
			.gsub(/\\/, '\\\\')
			.gsub(/\*/, '\\\*')
			.gsub(/\_/, '\\\_')
	end

	def update_pdf
		pdf_path = CONST::PDF_PATH
		begin
			Net::HTTP.start(CONST::PDF_DOMAIN) do |http|
				resp = http.get pdf_path
				open(pdf_file, 'w+') do |file|
					file.write resp.body
				end
			end
			@last_download = Time.now
			return true
		rescue
			return false
		end
	end

	def get_bandeco(day = nil, month = nil, period = nil, updated = false)
		# if current pdf is older than 2h, download a new one
		if (Time.now - @last_download) / 60 / 60 > 2
			update_pdf
		end

		# handle case of no specified date (get next meal)
		day, month, period = normalize_time(day, month, period)

		pdf_text = Reader.new(pdf_file).get_text

		meal = parse_meal(pdf_text, day, month)

		if meal[:lunch].empty? || meal[:dinner].empty?
			# if current date was not found, download pdf again and try once more
			update_pdf
			return get_bandeco day, month, period, true unless updated

			# this may be a bit confusing
			# if the pdf was already updated, 'updated' will be true
			# then we can set both dinner and lunch to the error_message
			# and return that instead of an empty message

			error_message = escape_md CONST::TEXTS[:error_message]
			meal[:dinner] = meal[:lunch] = error_message
		end

		msg = build_message(day, month, meal, period)
		msg
	end

	def normalize_time(day, month, period)
		day = Time.now.day unless day
		month = Time.now.month unless month
		period = nil unless period

		day = zero_pad day.to_s
		month = zero_pad month.to_s

		[day, month, period]
	end

	def parse_meal(pdf_text, day, _month)
		# we do not use the month here because people who
		# make the pdf often mess that up, causing the match
		# to fail even though the day is actually present
		day_regex = %r{
			#{day}\/\d?\d			# month day
			\n?								# zero or one new line
			\s								# make sure there is at least one whitespace
			(.+\n)+?					# capture as many lines as you can before
			\S								# reaching a non-whitespace character
		}x

		day_meal = day_regex.match pdf_text
		lunch = ''
		dinner = ''

		meal_regex = %r{
			(?:\d?\d\/\d?\d)? # any month day, may or may not be there (non-capture)
			\s*								# any amount of whitespaces
			(.+)							# capture as many characters as you can before (first column)
			\s\s							# at least two whitespaces (means column break)
			(?=\S)						# assert that there is a second column
			(.+)							# capture as many characters as you can (second column)
		}x

		day_meal.to_s.lines.each do |l|
			m = meal_regex.match(l)
			next unless m
			cap_lunch, cap_dinner = m.captures
			lunch << "\n" + cap_lunch unless /^$/ =~ cap_lunch
			dinner << "\n" + cap_dinner unless /^$/ =~ cap_dinner
		end

		{ lunch: lunch, dinner: dinner }
	end

	def build_message(day, month, meal, period = nil)
		if period.nil?
			time = Time.now
			if time.hour < 13 || (time.hour == 13 && time.min <= 15)
				CONST::TEXTS[:lunch_header, day.to_s, month.to_s, meal[:lunch].to_s]
			elsif time.hour > 20 || (time.hour == 19 && time.min >= 15)
				CONST::TEXTS[:fim_bandeco]
			else
				CONST::TEXTS[:dinner_header, day.to_s, month.to_s, meal[:dinner].to_s]
			end
		else
			ret = CONST::TEXTS[:wtf]
			CONST::PERIODS.each do |per|
				period == per && ret = CONST::TEXTS[:"#{per}_header", day.to_s, month.to_s, meal[per].to_s]
			end
			ret
		end
	end
end
