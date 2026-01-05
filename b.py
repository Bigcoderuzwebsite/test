import speech_recognition as sr

r = sr.Recognizer()
with sr.Microphone() as source:
    print("Gapiring...")
    audio = r.listen(source)

try:
    text = r.recognize_google(audio)  # til parametrini hozircha olib tashladik
    print("Siz aytdingiz:", text)
except sr.UnknownValueError:
    print("Ovoz tushunilmadi.")
except sr.RequestError as e:
    print("Xizmatga ulanishda xato:", e)
