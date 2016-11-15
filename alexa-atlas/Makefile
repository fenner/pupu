top-1m.csv: top-1m.csv.zip
	unzip $>

top-1m.csv.zip:
	wget http://s3.amazonaws.com/alexa-static/top-1m.csv.zip

targets.txt:	top-1m.csv
	python build-top-100.py
