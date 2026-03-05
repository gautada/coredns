import random
import requests
import yaml

config = None
with open("/etc/container/blacklist.yml", "r") as file:
    data = file.read()
    config = yaml.safe_load(data)
    
targets = config['targets']
bl_file = config['blacklist']

    
# blacklists = ['https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts',
#               'https://adaway.org/hosts.txt',
#               'https://v.firebog.net/hosts/AdguardDNS.txt',
#               'https://v.firebog.net/hosts/Admiral.txt',
#               'https://raw.githubusercontent.com/anudeepND/blacklist/master/adservers.txt',
#               'https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt'
#              ]

final = {}
for blacklist in blacklists:
    response = requests.get(blacklist)
    if 200 == response.status_code:
        # print( blacklist, response.status_code )
        lines = response.text.splitlines()
        for line in lines:
            trimmed = line.strip()
            token = None
            if 0 < len(trimmed) and '#' != trimmed[0]:
                tokens = trimmed.split()
                if 1 == len(tokens):
                    token = tokens[0]
                elif 2 == len(tokens):
                    token = tokens[1]
            # assert token is not None, "Blacklist token cannot be nil."
            if token is not None:
                if token not in final.keys():
                    final[token] = []
                # else:
                #     print("***")
                final[token].append(blacklist)
                
# Open for writing
print()
with open(bl_file, "w") as myfile:
    myfile.write("# %s\n" % len(final))
    for key in final.keys():
        myfile.write("%s %s\n" % (targets[random.randint(0, len(targets)-1)], key))




