from keras.utils import pad_sequences
from keras.models import Model
from keras.layers import Dense, Embedding, LSTM, Input
from keras.utils import to_categorical
from keras import optimizers
import numpy as np
import re
import pickle
from project_main import veri_temizligi


def predict(prepro1, enc_model, dec_model, dense, MAX_LEN, vocab, inv_vocab):
    soru = prepro1
    sayac = 0
    while sayac < 3:
        sayac += 1
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
            sample_word = inv_vocab[sample_word_index] + ' '
            
            if sample_word != '<EOS> ':
                decoded_translation += sample_word

            if sample_word == '<EOS> ' or len(decoded_translation.split()) > MAX_LEN:
                stop_condition = True

            empty_target_seq = np.zeros((1, 1))
            empty_target_seq[0, 0] = sample_word_index
            stat = [h, c]
            
        print(f'Sen: {soru}')    
        print(f'Chatbot: {decoded_translation.title()}')  
        break

# Modelleri ve verileri yükleme
with open('models_and_data.pkl', 'rb') as f:
    enc_model, dec_model, dense, MAX_LEN, vocab, inv_vocab = pickle.load(f)


user_input = "üniversitemizde mezuniyette bilmemne bilmemne"
predict(user_input, enc_model, dec_model, dense, MAX_LEN, vocab, inv_vocab)