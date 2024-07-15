from fastapi import FastAPI
import requests
from bs4 import BeautifulSoup
from datetime import datetime
import http.client
import requests
import requests
from datetime import datetime


app = FastAPI()

@app.get("/gunun-yemegi")
def gunun_yemegi():
    url = "https://sks.omu.edu.tr/gunun-yemegi/"
    response = requests.get(url)
    soup = BeautifulSoup(response.content, "html.parser")

    table = soup.findAll("table") 

    rows = table[-1].find_all("tr")
    
    today = "16.07.2024"



    for row in rows:
        cols = row.find_all("td")

        if cols:
            day = cols[0].text.strip()
            print(cols[0].text)
            print(today.strip())
            if day == today.strip():
                gunun_yemegi = {"1.yemek": cols[1].text,"2.yemek":cols[2].text,"3.yemek":cols[3].text,"4.yemek":cols[4].text}
                return gunun_yemegi

    return {"gunun_yemegi": "Yemek bulunamadı"}



# API isteği için gerekli bilgiler
url = "https://api.collectapi.com/weather/getWeather"
headers = {
    'content-type': "application/json",
    'authorization': "apikey 4kFdVg7hGAhRPpBiiyDm12:6KQ9k2DGYJmqwFtGi0oBar"
}

# API'ye GET isteği gönderme
response = requests.get(url, headers=headers, params={"data.lang": "tr", "data.city": "samsun"})

# JSON formatında gelen cevabı okuma
data = response.json()

# Bugünün tarihini alıyoruz
bugun = datetime.now().strftime("%d.%m.%Y")

# Gerekli bilgileri alıp yazdırma
if data["success"]:
    for result in data["result"]:
        if result["date"] == bugun:
            print("Gün:", result["day"])
            print("Şehir:", data["city"])
            print("Sıcaklık:", result["degree"] + " °C")
            print("Durum:", result["description"])
            print("="*30)
            break  # Sadece bugünün verisini aldık, döngüden çıkıyoruz
else:
    print("Hata: API'den veri alınamadı.")
