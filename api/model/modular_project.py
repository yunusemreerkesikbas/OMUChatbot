import re
import numpy as np
from keras.utils import pad_sequences
from keras.models import Model
from keras.layers import Input, LSTM, Dense, Embedding
from keras.utils import to_categorical

def load_data(file_path):
    with open(file_path, encoding='utf-8') as file:
        data = file.readlines()
    temp = list(map(lambda x: x.split('~'), list(map(lambda x: x.replace('\n', ''), data))))
    return temp

def split_data(data):
    questions = list(map(lambda x: x[0], data))
    answers = list(map(lambda x: x[1], data))
    return questions, answers

def load_stopwords(file_path):
    with open(file_path, "r", encoding='utf-8') as file:
        stopwords = set(file.read().replace("\n", " ").split())
    return stopwords

def clean_text(text, stopwords):
    text = re.sub("[^a-zA-ZçÇğĞıİöÖşŞüÜ]", " ", text).lower()
    words = text.split()
    words = [word for word in words if word not in stopwords]
    return words

def update_dataset(data, stopwords):
    max_len = 0
    for i in range(len(data)):
        words = clean_text(data[i], stopwords)
        max_len = max(max_len, len(words))
        data[i] = " ".join(words)
    return data, max_len

def build_vocab(data):
    vocab = {}
    inv_vocab = {}
    word_index = 1
    for line in data:
        for word in line.split():
            if word not in vocab:
                vocab[word] = word_index
                inv_vocab[word_index] = word
                word_index += 1
    return vocab, inv_vocab

def preprocess_data(data, vocab, max_len):
    sequences = []
    for line in data:
        seq = [vocab.get(word, vocab['<OUT>']) for word in line.split()]
        sequences.append(seq)
    return pad_sequences(sequences, max_len, padding='post', truncating='post')

def build_model(vocab_size, max_len):
    encoder_inputs = Input(shape=(max_len,))
    encoder_embedding = Embedding(vocab_size, 256, mask_zero=True)(encoder_inputs)
    encoder_lstm = LSTM(256, return_state=True)
    encoder_outputs, state_h, state_c = encoder_lstm(encoder_embedding)
    encoder_states = [state_h, state_c]

    decoder_inputs = Input(shape=(None,))
    decoder_embedding = Embedding(vocab_size, 256, mask_zero=True)(decoder_inputs)
    decoder_lstm = LSTM(256, return_sequences=True, return_state=True)
    decoder_outputs, _, _ = decoder_lstm(decoder_embedding, initial_state=encoder_states)
    decoder_dense = Dense(vocab_size, activation='softmax')
    output = decoder_dense(decoder_outputs)

    model = Model([encoder_inputs, decoder_inputs], output)
    return model

def train_model(model, questions, answers, vocab_size, max_len, batch_size, epochs):
    answers_input = np.zeros((answers.shape[0], max_len), dtype='int32')
    answers_output = np.zeros((answers.shape[0], max_len, vocab_size), dtype='float32')

    for i in range(answers.shape[0]):
        for t in range(1, max_len):
            answers_input[i, t] = answers[i, t-1]
            if t < max_len - 1:
                answers_output[i, t, answers[i, t]] = 1.
            else:
                answers_output[i, t, 0] = 1.

    model.compile(optimizer='rmsprop', loss='categorical_crossentropy', metrics=['accuracy'])
    model.fit([questions, answers_input], answers_output, batch_size=batch_size, epochs=epochs, validation_split=0.2)
    return model

def chatbot_response(user_input, vocab, inv_vocab, enc_model, dec_model, max_len):
    processed_input = ' '.join(clean_text(user_input, stopwords))
    input_seq = [processed_input]

    txt = []
    for x in input_seq:
        lst = []
        for y in x.split():
            lst.append(vocab.get(y, vocab['<OUT>']))
        txt.append(lst)

    txt = pad_sequences(txt, max_len, padding='post', truncating='post')
    stat = enc_model.predict(txt)

    empty_target_seq = np.zeros((1, 1))
    empty_target_seq[0, 0] = vocab['<SOS>']

    stop_condition = False
    decoded_translation = ''

    while not stop_condition:
        dec_outputs, h, c = dec_model.predict([empty_target_seq] + stat)
        decoder_concat_input = dec_outputs
        sample_word_index = np.argmax(decoder_concat_input[0, -1, :])
        sample_word = inv_vocab[sample_word_index] + ' '

        if sample_word != '<EOS> ':
            decoded_translation += sample_word

        if sample_word == '<EOS> ' or len(decoded_translation.split()) > max_len:
            stop_condition = True

        empty_target_seq = np.zeros((1, 1))
        empty_target_seq[0, 0] = sample_word_index
        stat = [h, c]

    return decoded_translation.title()

if __name__ == "__main__":
    dataset_path = "/Users/metehankarabulut/Desktop/OMUChatbot/api/model/dataset.txt"
    stopwords_path = "/Users/metehankarabulut/Desktop/OMUChatbot/api/model/turkce-stop-words.txt"

    data = load_data(dataset_path)
    questions, answers = split_data(data)
    stopwords = load_stopwords(stopwords_path)

    questions, max_len_question = update_dataset(questions, stopwords)
    answers, max_len_answer = update_dataset(answers, stopwords)

    max_len = max(max_len_question, max_len_answer)

    vocab, inv_vocab = build_vocab(questions + answers)
    vocab['<OUT>'] = len(vocab) + 1
    vocab['<SOS>'] = len(vocab) + 2
    vocab['<EOS>'] = len(vocab) + 3

    questions_seq = preprocess_data(questions, vocab, max_len)
    answers_seq = preprocess_data(answers, vocab, max_len)

    model = build_model(len(vocab) + 1, max_len)
    model = train_model(model, questions_seq, answers_seq, len(vocab) + 1, max_len, batch_size=64, epochs=60)

    while True:
        user_input = "Tarihi bir tur yapmak istediğimde nereyi gezmeliyim?"
        if user_input.lower() in ['exit', 'quit']:
            break
        response = chatbot_response(user_input, vocab, inv_vocab, model, model, max_len)
        print(f'Chatbot: {response}')
