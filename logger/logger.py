import sys
from bottle import run, post, request

PORT = 1337
LOGFILE = 'output.log'

@post('/log')
def log():
	global fp
	fp.write(request.body.read() + "\n")
	fp.flush()

if __name__ == "__main__":
	# parse cmd line
	try:
		me, output = sys.argv
	except:
		output = LOGFILE

	# open output file
	fp = file(output, "a+t")

	# start server
	run(port=PORT)