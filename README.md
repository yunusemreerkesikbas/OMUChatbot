
# OMUChatbot

## Description

OMUChatbot, Ondokuz Mayıs Üniversitesi öğrencileri için geliştirilmiş bir yapay zeka chatbot projesidir. Bu proje, doğal dil işleme (NLP) teknikleri kullanarak öğrencilere akademik konularda yardımcı olmayı ve genel sorulara yanıt vermeyi amaçlamaktadır. Flutter ile geliştirilen kullanıcı arayüzü, kullanıcı dostu bir deneyim sunarken, arka planda FastAPI ve Keras ile desteklenen güçlü bir yapay zeka modeli çalışmaktadır.

## Technologies

Bu projede kullanılan ana teknolojiler şunlardır:

- **Flutter**: Mobil uygulama geliştirme için kullanılan açık kaynaklı bir UI yazılım geliştirme kitidir.
- **FastAPI**: Modern, hızlı (yüksek performanslı) web framework'ü, Python'da API geliştirmek için kullanılır.
- **Keras**: Python'da derin öğrenme modelleri oluşturmak için kullanılan yüksek seviyeli bir sinir ağı API'sidir.
- **TensorFlow**: Derin öğrenme modelleri için açık kaynaklı bir kütüphanedir, Keras ile entegre çalışır.
- **SQLite**: Proje veritabanı olarak kullanılan hafif, disk tabanlı bir veritabanıdır.
- **Python**: Backend ve yapay zeka model geliştirmede kullanılan programlama dilidir.

## Features

- **Doğal Dil İşleme**: Kullanıcıların sorularını anlayarak uygun yanıtlar üretir.
- **Özelleştirilebilir Model**: Kendi veri setinizle modeli eğitme ve güncelleme imkanı sağlar.
- **Kullanıcı Dostu Arayüz**: Flutter ile geliştirilmiş modern ve sezgisel bir kullanıcı arayüzü.
- **Kolay Entegrasyon**: FastAPI üzerinden diğer sistemlerle kolayca entegre edilebilir.
- **Çoklu Platform Desteği**: Hem Android hem de iOS cihazlarda çalışabilir.

## Installation

Projeyi kendi sisteminize kurmak için aşağıdaki adımları izleyin:

### Gereksinimler

- **Flutter SDK**: [İndir ve kurulum talimatları](https://flutter.dev/docs/get-started/install)
- **Python 3.7+**: [Python indirme bağlantısı](https://www.python.org/downloads/)
- **Git**: [Git kurulum talimatları](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
- **Keras ve TensorFlow**: `pip install keras tensorflow`

### Adımlar

1. **Projeyi Klonlayın**:
   ```bash
   git clone https://github.com/yunusemreerkesikbas/OMUChatbot.git
   cd OMUChatbot
   ```

2. **Python Sanal Ortamı Oluşturun ve Etkinleştirin**:
   ```bash
   python -m venv venv
   source venv/bin/activate  # Windows için: venv\Scripts\activate
   ```

3. **Gerekli Python Paketlerini Yükleyin**:
   ```bash
   pip install -r backend/requirements.txt
   ```

4. **Flutter Bağımlılıklarını Yükleyin**:
   ```bash
   cd frontend
   flutter pub get
   ```

5. **Backend Sunucusunu Başlatın**:
   ```bash
   cd ../backend
   uvicorn main:app --reload
   ```

6. **Flutter Uygulamasını Çalıştırın**:
   ```bash
   cd ../frontend
   flutter run
   ```

Proje hakkında daha fazla bilgi ve destek için lütfen [proje sayfasını](https://github.com/yunusemreerkesikbas/OMUChatbot) ziyaret edin.

## Lisans

Bu proje MIT Lisansı altında lisanslanmıştır. Daha fazla bilgi için `LICENSE` dosyasına bakınız.
