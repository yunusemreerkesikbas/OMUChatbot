import numpy as np
import tensorflow as tf
from tensorflow.keras.models import Model
from tensorflow.keras.layers import Input, LSTM, Dense, Embedding
from tensorflow.keras.preprocessing.text import Tokenizer
from tensorflow.keras.preprocessing.sequence import pad_sequences
import os
import re
import pickle

class Seq2SeqModel:
    def __init__(self):
        self.MAX_VOCAB_SIZE = 10000
        self.MAX_SEQUENCE_LENGTH = 100
        self.LATENT_DIM = 256
        self.tokenizer = Tokenizer(num_words=self.MAX_VOCAB_SIZE, filters='')

    def load_data(self):
        conversations = []
        lines = {}
        base_path = os.path.join('/home/enoca2/Desktop/OMUChatbot/data/cornell_movie_dialogs_corpus')
        with open(os.path.join(base_path, 'movie_conversations.txt'), 'r', encoding='iso-8859-1') as file:
            conv_lines = file.readlines()[:1000]  # İlk 1,000 satırı kullanarak veri setini küçültme
        with open(os.path.join(base_path, 'movie_lines.txt'), 'r', encoding='iso-8859-1') as file:
            for line in file:
                parts = line.strip().split(' +++$+++ ')
                lines[parts[0]] = parts[-1]
        for line in conv_lines:
            parts = line.strip().split(' +++$+++ ')
            conversations.append(parts[-1][1:-1].replace("'", "").split(", "))
        questions = []
        answers = []
        for conv in conversations:
            for i in range(len(conv) - 1):
                questions.append(self.preprocess_text(lines[conv[i]]))
                answers.append('start ' + self.preprocess_text(lines[conv[i + 1]]) + ' end')
        return questions, answers

    def preprocess_text(self, text):
        text = text.lower()
        text = re.sub(r"i'm", "i am", text)
        text = re.sub(r"he's", "he is", text)
        text = re.sub(r"she's", "she is", text)
        text = re.sub(r"it's", "it is", text)
        text = re.sub(r"that's", "that is", text)
        text = re.sub(r"what's", "what is", text)
        text = re.sub(r"where's", "where is", text)
        text = re.sub(r"how's", "how is", text)
        text = re.sub(r"\'ll", " will", text)
        text = re.sub(r"\'ve", " have", text)
        text = re.sub(r"\'re", " are", text)
        text = re.sub(r"\'d", " would", text)
        text = re.sub(r"\'re", " are", text)
        text = re.sub(r"won't", "will not", text)
        text = re.sub(r"can't", "cannot", text)
        text = re.sub(r"n't", " not", text)
        text = re.sub(r"n'", "ng", text)
        text is re.sub(r"'bout", "about", text)
        text is re.sub(r"'til", "until", text)
        text is re.sub(r"[-()\"#/@;:<>{}`+=~|.!?,]", "", text)
        return text

    def build_model(self):
        questions, answers = self.load_data()
        self.tokenizer.fit_on_texts(questions + answers)
        word_index = self.tokenizer.word_index

        encoder_input_data = self.tokenizer.texts_to_sequences(questions)
        decoder_input_data = self.tokenizer.texts_to_sequences(answers)
        decoder_target_data = [seq[1:] for seq in decoder_input_data]

        encoder_input_data = pad_sequences(encoder_input_data, maxlen=self.MAX_SEQUENCE_LENGTH, padding='post')
        decoder_input_data = pad_sequences(decoder_input_data, maxlen=self.MAX_SEQUENCE_LENGTH, padding='post')
        decoder_target_data = pad_sequences(decoder_target_data, maxlen=self.MAX_SEQUENCE_LENGTH, padding='post')

        self.encoder_input_data = encoder_input_data
        self.decoder_input_data = decoder_input_data
        self.decoder_target_data = np.expand_dims(decoder_target_data, -1)

        encoder_inputs = Input(shape=(None,), name='encoder_inputs')
        enc_emb = Embedding(input_dim=len(word_index)+1, output_dim=self.LATENT_DIM, name='encoder_embedding')(encoder_inputs)
        encoder_lstm = LSTM(self.LATENT_DIM, return_state=True, name='encoder_lstm')
        encoder_outputs, state_h, state_c = encoder_lstm(enc_emb)
        encoder_states = [state_h, state_c]

        decoder_inputs = Input(shape=(None,), name='decoder_inputs')
        dec_emb_layer = Embedding(input_dim=len(word_index)+1, output_dim=self.LATENT_DIM, name='decoder_embedding')
        dec_emb = dec_emb_layer(decoder_inputs)
        decoder_lstm = LSTM(self.LATENT_DIM, return_sequences=True, return_state=True, name='decoder_lstm')
        decoder_outputs, _, _ = decoder_lstm(dec_emb, initial_state=encoder_states)
        decoder_dense = Dense(len(word_index)+1, activation='softmax', name='decoder_dense')
        decoder_outputs = decoder_dense(decoder_outputs)

        self.model = Model([encoder_inputs, decoder_inputs], decoder_outputs)
        self.model.compile(optimizer='rmsprop', loss='sparse_categorical_crossentropy')

    def train(self, epochs=10, batch_size=128):
        self.model.fit([self.encoder_input_data, self.decoder_input_data], self.decoder_target_data,
                       batch_size=batch_size,
                       epochs=epochs,
                       validation_split=0.2)
        with open('/home/enoca2/Desktop/OMUChatbot/models/tokenizer.pkl', 'wb') as f:
            pickle.dump(self.tokenizer, f)

    def save_model(self, path):
        self.model.save(path)
        with open('/home/enoca2/Desktop/OMUChatbot/models/tokenizer.pkl', 'wb') as f:
            pickle.dump(self.tokenizer, f)

    def load_model(self, path):
        self.model = tf.keras.models.load_model(path)
        with open('/home/enoca2/Desktop/OMUChatbot/models/tokenizer.pkl', 'rb') as f:
            self.tokenizer = pickle.load(f)
        self.build_inference_models()

    def build_inference_models(self):
        encoder_inputs = self.model.input[0]  # Encoder input layer
        encoder_outputs, state_h_enc, state_c_enc = self.model.get_layer('encoder_lstm').output  # Encoder LSTM layer
        self.encoder_model = Model(encoder_inputs, [state_h_enc, state_c_enc])

        decoder_inputs = self.model.input[1]  # Decoder input layer
        decoder_state_input_h = Input(shape=(self.LATENT_DIM,), name='decoder_state_input_h')
        decoder_state_input_c = Input(shape=(self.LATENT_DIM,), name='decoder_state_input_c')
        decoder_states_inputs = [decoder_state_input_h, decoder_state_input_c]
        dec_emb_layer = self.model.get_layer('decoder_embedding')
        dec_emb = dec_emb_layer(decoder_inputs)
        decoder_lstm = self.model.get_layer('decoder_lstm')
        decoder_outputs, state_h_dec, state_c_dec = decoder_lstm(dec_emb, initial_state=decoder_states_inputs)
        decoder_states = [state_h_dec, state_c_dec]
        decoder_dense = self.model.get_layer('decoder_dense')
        decoder_outputs = decoder_dense(decoder_outputs)
        self.decoder_model = Model(
            [decoder_inputs] + decoder_states_inputs,
            [decoder_outputs] + decoder_states)

    def generate_response(self, input_text):
        input_seq = self.tokenizer.texts_to_sequences([input_text])
        input_seq = pad_sequences(input_seq, maxlen=self.MAX_SEQUENCE_LENGTH, padding='post')

        states_value = self.encoder_model.predict(input_seq)

        target_seq = np.zeros((1, 1))
        target_seq[0, 0] = self.tokenizer.word_index.get('start', 0)

        stop_condition = False
        decoded_sentence = ''
        while not stop_condition:
            output_tokens, h, c = self.decoder_model.predict(
                [target_seq] + states_value)

            sampled_token_index = np.argmax(output_tokens[0, -1, :])
            sampled_word = self.tokenizer.index_word.get(sampled_token_index, '')

            if sampled_word == 'end' or len(decoded_sentence) > self.MAX_SEQUENCE_LENGTH:
                stop_condition = True
            else:
                decoded_sentence += ' ' + sampled_word

            target_seq = np.zeros((1, 1))
            target_seq[0, 0] = sampled_token_index

            states_value = [h, c]

        return decoded_sentence.strip()

if __name__ == "__main__":
    seq2seq = Seq2SeqModel()
    seq2seq.load_model('seq2seq_model.keras')
    print(seq2seq.generate_response("how are you doing"))


