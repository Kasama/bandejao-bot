require File.expand_path './constants.rb'

class Bandejao
	attr_accessor :pdf_file

	def initialize(pdf)
		@pdf_file = pdf
		@last_download = Time.now
	end

	def zero_pad(str)
		if str.length == 1
			'0' + str
		else
			str
		end
	end

	def update_pdf
		pdf_path = CONST::PDF_PATH
		Net::HTTP.start(CONST::PDF_DOMAIN) do |http|
			resp = http.get pdf_path
			open(pdf_file, "w+") do |file|
				file.write resp.body
			end
		end
	end

	def get_today
		Time.new
	end

	def get_bandeco (day = Time.now.day, month = Time.now.month, horario = nil)
		reader = PDF::Reader.new(pdf_file)

		day = zero_pad day.to_s
		month = zero_pad month.to_s

		time = Time.now
		day_regex = /#{day}\/#{month}(.+\n)+/

		day_meal = nil
		reader.pages.each do |page|
			day_meal = day_regex.match page.text if day_meal.nil?
		end

		lunch = ''
		dinner = ''

		day_meal.to_s.lines.each do |l|
			cap_lunch, cap_dinner = /\s+(.+)\s\s(.+)/.match(l).captures
			lunch = lunch + "\n" + cap_lunch
			dinner = dinner + "\n" + cap_dinner
		end

		if lunch.length == 0
			lunch = "\nOu não tem bandeco dia #{day}/#{month} ou o cardápio ainda não foi atualizado"
		end
		if dinner.length == 0
			dinner = "\nOu não tem bandeco dia #{day}/#{month} ou o cardápio ainda não foi atualizado"
		end

		if horario.nil?
			if (time.hour < 13 || (time.hour == 13 && time.min <= 15))
				"*Almoço (#{day}/#{month})*:" + lunch
			elsif (time.hour > 20 || (time.hour == 19 && time.min >= 15))
				"Ja era seu *bandeco*, fi"
			else
				"Janta (#{day}/#{month}):" + dinner
			end
		else
			if horario == :almoco
				"*Almoço* (#{day}/#{month}):" + lunch
			elsif horario == :janta
				"Janta (#{day}/#{month}):" + dinner
			else
				"WTF?"
			end
		end
	end
end
