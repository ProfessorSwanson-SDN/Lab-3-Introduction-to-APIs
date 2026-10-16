import http.client

conn = http.client.HTTPSConnection("icanhazdadjoke.com")
payload = ''
headers = {
  'Accept': 'application/json'
}
conn.request("GET", "/", payload, headers)
res = conn.getresponse()
data = res.read()
print(data.decode("utf-8"))