#!/grid/common/pkgs/python/latest/bin/python
# Using Python off this location for the 2.7
import json                                 
import os.path                              
import optparse                             
import requests                             
from requests.auth import HTTPBasicAuth     

# DEFINE THE INPUT PARSER

def get_opts() :
        parser = optparse.OptionParser()
        parser.add_option('-p', '--port'        ,action="store",          dest="port", help="Port, default 8080", default="8080")
        parser.add_option('-s', '--server'      ,action="store",          dest="srv", help="Server", default="vl-neden")
        parser.add_option('-d', '--desc'        ,action="store",          dest="desc", help="Description")
        parser.add_option('-j', '--json'        ,action="store",          dest="json", help="JSON file")
        parser.add_option(      '--summary'     ,action="store",          dest="summary", help="Summary")
        parser.add_option(      '--id'          ,action="store",          dest="id", help="JIRA ID, to be used only with op=search")
        parser.add_option(      '--op'          ,action="store",          dest="op", help="issue (default) or search", default="issue")
        parser.add_option('-v'                  ,action="store_true", dest="verbose", help="Print debug messages", default=False)
        options, args = parser.parse_args()
        return options


def get_json (file):
        "This function creates a JSON object from a file"
        if ( os.path.exists(file) and os.path.getsize(file) ) > 0 :
                with open (file) as json_file :
                        json_data = json.load(json_file)
                        if (options.op == 'search') :
                                json_data['jql'] = "project=NAD & key="+str(options.id);
                        else :
                                json_data['summary'] = options.summary
                                json_data['desc']        = options.desc
                        return json_data
        else :
                print "-E- '"+file + "' is either non existing or empty"
                quit(1)

def create_post (js, url):
        "This function creates a POST request based on the JSON and URL"
        headers = {'content-type': 'application/json', 'accept':'application/json'}
        req = requests.post(url, json=js, headers=headers, auth=HTTPBasicAuth('neden', 'letmein'))
        if ( req.status_code == 200 or req.status_code == 201 ) :
                return req
        else :
                print "-E- POST Request to URL:"+url+" Has Failed with status:"+str(req.status_code)
                print json.dumps(json.loads(req.text),indent=4)
                quit(1)

options = get_opts()
url = "http://"+options.srv+":"+options.port+"/rest/api/2/"+options.op+"/"
if options.verbose : print url
json_file = get_json(options.json)
if options.verbose : print json.dumps(json_file, indent=4)
req = create_post(json_file, url)
if options.verbose : print json.dumps(json.loads(req.text), indent=4)
