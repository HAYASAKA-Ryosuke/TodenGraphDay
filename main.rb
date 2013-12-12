require 'gruff'
require 'csv'
require 'sinatra'
require 'date'
require 'json'

def graphgenerate(xlabels,y,x_name,y_name,graphname) 
	g = Gruff::Line.new
	g.title = graphname
	g.data(graphname,y)
	g.labels = xlabels 
	g.x_axis_label = x_name
	g.y_axis_label = y_name
	g.write('./public/'+graphname+'.png')
end

def filedownload(url,filename)
	system('wget '+url+' -O'+ filename)
	system('nkf -w --overwrite '+ filename)
end

def todayfileanalysis()
	if((DateTime.now.to_time-File.stat("./juyo-j.csv").mtime.to_time).to_i > 0) then
		filedownload('http://www.tepco.co.jp/forecast/html/images/juyo-j.csv','juyo-j.csv')
		powerdata=[]
		count = 0
		datatime=""
		CSV.foreach("./juyo-j.csv","r") do |data|
			if(count==0) then
				datatime=data[0]
			end
			if(count>46) then
				powerdata << data[2].to_f*10000/10**6#kWはわかりにくいのでMW
			end
			count=count+1
		end
	end
	xlabels={0 => '0',12 => '1',24 => '2',36 => '3',48 => '4',60 => '5',72 => '6',84 => '7',96 => '8',108 => '9',120 => '10',132 => '11',144 => '12',156 => '13',168 => '14',180 => '15',192 => '16',204 => '17',216 => '18',228 => '19',240 => '20',252 => '21',264 => '22',276 => '23'}
	graphgenerate(xlabels,powerdata,'Hour','Power Usage[MW]','PowerUsageGraph')
	return datatime

end

def pastfileanalysis(dateyear,datemonth,dateday)
	filename=dateyear.to_s+'-'+datemonth.to_s+'-'+dateday.to_s+'.json'
	if(File.exist?(filename)==false) then
		url='http://tepco-usage-api.appspot.com/'+dateyear.to_s+'/'+datemonth.to_s+'/'+dateday.to_s+'.json'
		filedownload(url,filename)
		powerdata=[]
		jsondata=open(filename).read
		jsonpowerdata = JSON.parser.new(jsondata).parse()
		jsonpowerdata.each do |data|
			powerdata << data['usage'].to_f*10000/10**6#kWはわかりにくいのでMW
		end
		xlabels={0 => '0',1 => '1',2 => '2',3 => '3',4 => '4',5 => '5',6 => '6',7 => '7',8 => '8',9 => '9',10 => '10',11 => '11',12 => '12',13 => '13',14 => '14',15 => '15',16 => '16',17 => '17',18 => '18',19 => '19',20 => '20',21 => '21',22 => '22',23 => '23'}
		graphgenerate(xlabels,powerdata,'Hour','Power Usage[MW]','PowerUsageGraph'+dateyear.to_s+'-'+datemonth.to_s+'-'+dateday.to_s)
	end
	return ""
end

set :bind, '0.0.0.0'

get '/' do
	dateparam=params[:date].to_i
	dateyear=(Date.today-dateparam).year
	datemon=(Date.today-dateparam).mon
	dateday=(Date.today-dateparam).mday
	if(dateparam>0) then
		@graphdatetime=pastfileanalysis(dateyear,datemon,dateday)
		@graphimage='PowerUsageGraph'+dateyear.to_s+'-'+datemon.to_s+'-'+dateday.to_s+'.png'
	else
		@graphdatetime=todayfileanalysis
		@graphimage="PowerUsageGraph.png"
	end
	erb :index
end
