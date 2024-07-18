from keras.preprocessing.sequence import pad_sequences
from keras.models import Model
from keras.layers import Dense, Embedding, LSTM, Input
from keras.utils import to_categorical
from keras import optimizers
import numpy as np
import re
import pickle
import mysql.connector
from pathlib import Path


# Dosya yollarını belirleme
BASE_DIR = Path(__file__).resolve().parent.parent
SAVED_MODEL_PATH = BASE_DIR / "model" / "saved_models"
STOPWORDS_PATH = BASE_DIR / "model" / "turkce-stop-words.txt"

def data_load():
    db_connection = mysql.connector.connect(
        host="localhost",
        port=3307,
        user="chatbot_user",
        password="chatbot_db_1234",
        database="chatbot_db",
        charset='utf8mb4',
        collation='utf8mb4_unicode_ci'
    )
    cursor = db_connection.cursor()
    cursor.execute("SELECT question, answer FROM chatbot_data")
    data = cursor.fetchall()
    db_connection.close()

    questions = [item[0] for item in data]
    answers = [item[1] for item in data]

    with open(STOPWORDS_PATH, "r", encoding='utf-8') as file:
        turkish_stopwords = set(file.read().replace("\n", " ").split())

    return turkish_stopwords, questions, answers

def veri_temizligi(text):
    turkish_stopwords, _, _ = data_load()
    metin = re.sub("[^a-zA-ZçÇğĞıİöÖşŞüÜ]", " ", text).lower()
    kelimeler = metin.split()
    kelimeler = [i for i in kelimeler if not i in turkish_stopwords]
    return kelimeler

def veri_temizligi2(text):
    metin = re.sub("[^a-zA-ZçÇğĞıİöÖşŞüÜ]", " ", text).lower()
    kelimeler = metin.split()
    kelimeler = [i for i in kelimeler]
    
    return kelimeler

def update_dataset(data, control = True):
    MAX_LEN = 0
    for i in range(len(data)):
        kokler = veri_temizligi(data[i]) if control else veri_temizligi2(data[i])
        MAX_LEN = len(kokler) if MAX_LEN < len(kokler) else MAX_LEN
        data[i] = " ".join(kokler)
    return data, MAX_LEN

def building_vocab():
    _, questions, answers = data_load()
    questions_data, MAX_LEN_QUESTION = update_dataset(questions)
    answers_data, MAX_LEN_ANSWER = update_dataset(answers, False)

    MAX_LEN = max(MAX_LEN_ANSWER, MAX_LEN_QUESTION)

    vocab = {}

    temp_list = answers_data + questions_data
    word_num = 0

    for line in temp_list:
        for i in line.split():
            if not i in vocab:
                vocab[i] = word_num
                word_num += 1

    for i in range(len(answers_data)):
        answers_data[i] = '<SOS> ' + answers_data[i] + ' <EOS>'

    tokens = ['<PAD>', '<EOS>', '<OUT>', '<SOS>']

    length_of_vocab = len(vocab)

    for token in tokens:
        vocab[token] = length_of_vocab
        length_of_vocab += 1

    vocab[list(vocab.items())[0][0]] = vocab['<PAD>']
    vocab['<PAD>'] = 0
    inv_vocab = {v: k for k, v in vocab.items()}

    return MAX_LEN, vocab, inv_vocab, questions_data, answers_data

def decoder_encoder(input, vocab):
    main_list = []
    for line in input:
        temp_list = []
        for word in line.split():
            temp_list.append(vocab['<OUT>'] if word not in vocab else vocab[word])
        main_list.append(temp_list)
    return main_list

def building_model():
    MAX_LEN, vocab, inv_vocab, questions_data, answers_data = building_vocab()

    encoder_input = decoder_encoder(questions_data, vocab)
    decoder_input = decoder_encoder(answers_data, vocab)

    encoder_input = pad_sequences(encoder_input, MAX_LEN, padding="post", truncating="post")
    decoder_input = pad_sequences(decoder_input, MAX_LEN, padding="post", truncating="post")

    decoder_final_output = pad_sequences(list(map(lambda x: x[1:], decoder_input)), MAX_LEN, padding="post", truncating="post")

    VOCAB_SIZE = len(vocab)

    decoder_final_output = to_categorical(decoder_final_output, len(vocab))

    enc_inp = Input(shape=(MAX_LEN,))
    dec_inp = Input(shape=(MAX_LEN,))

    embed = Embedding(len(vocab) + 1, output_dim=50, input_length=MAX_LEN, trainable=True)

    enc_embed = embed(enc_inp)
    enc_lstm = LSTM(128, return_sequences=True, return_state=True)
    enc_op, h, c = enc_lstm(enc_embed)
    enc_states = [h, c]

    dec_embed = embed(dec_inp)
    dec_lstm = LSTM(128, return_sequences=True, return_state=True)
    dec_op, _, _ = dec_lstm(dec_embed, initial_state=enc_states)

    dense = Dense(len(vocab), activation='softmax')
    dense_op = dense(dec_op)

    model = Model([enc_inp, dec_inp], dense_op)

    opt = optimizers.Adam(learning_rate=0.0125)

    model.compile(loss='categorical_crossentropy', metrics=['accuracy'], optimizer=opt)
    model.fit([encoder_input, decoder_input], decoder_final_output, epochs=10)

    enc_model = Model([enc_inp], enc_states)

    decoder_state_input_h = Input(shape=(128,))
    decoder_state_input_c = Input(shape=(128,))

    decoder_states_inputs = [decoder_state_input_h, decoder_state_input_c]

    decoder_outputs, state_h, state_c = dec_lstm(dec_embed, initial_state=decoder_states_inputs)
    decoder_states = [state_h, state_c]

    dec_model = Model([dec_inp] + decoder_states_inputs, [decoder_outputs] + decoder_states)

    return VOCAB_SIZE, enc_model, dec_model, dense

def predict(prepro1, enc_model, dec_model, dense, MAX_LEN, vocab, inv_vocab):

    prepro1 = ' '.join(veri_temizligi(prepro1))
    prepro = [prepro1]

    txt = []
    for x in prepro:
        lst = []
        for y in x.split():
            try:
                lst.append(vocab[y])
            except:
                lst.append(vocab['<OUT>'])

        txt.append(lst)

    txt = pad_sequences(txt, MAX_LEN, padding='post', truncating="post")

    stat = enc_model.predict(txt)
    empty_target_seq = np.zeros((1, 1))
    empty_target_seq[0, 0] = vocab['<SOS>']

    stop_condition = False
    decoded_translation = ''

    while not stop_condition:
        dec_outputs, h, c = dec_model.predict([empty_target_seq] + stat)
        decoder_concat_input = dense(dec_outputs)

        sample_word_index = np.argmax(decoder_concat_input[0, -1, :])
        sample_word = inv_vocab[sample_word_index]

        if sample_word != '<EOS>' and sample_word != '<PAD>':
            decoded_translation += sample_word + ' '

        if sample_word == '<EOS>' or len(decoded_translation.split()) > MAX_LEN:
            stop_condition = True

        empty_target_seq = np.zeros((1, 1))
        empty_target_seq[0, 0] = sample_word_index
        stat = [h, c]

        
    return decoded_translation.title().strip()

if __name__ == "__main__":
    _, enc_model, dec_model, dense = building_model()
    MAX_LEN, vocab, inv_vocab, _, _ = building_vocab()
    print(MAX_LEN)
    print(len(vocab))
    enc_model.save(SAVED_MODEL_PATH / 'enc_model.h5')
    dec_model.save(SAVED_MODEL_PATH / 'dec_model.h5')

    with open(SAVED_MODEL_PATH / 'storage.pkl', 'wb') as f:
        pickle.dump((dense, MAX_LEN, vocab, inv_vocab), f)



