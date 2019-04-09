#!/usr/bin/python3.6

import requests, bs4, re

s=requests.get('https://airvpn.org/status/')
b=bs4.BeautifulSoup(s.text, "html.parser")

p3=b.select('.air_server_box_1 ')

d3 = set(p3)

for elem in d3:
   a3=elem.getText()
   # print(a3.strip().split("  "))
   z=(a3.strip())
   print(z)


#./air_servers.py | cut -d' ' -f1
