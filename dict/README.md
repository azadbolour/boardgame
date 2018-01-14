
## Dictionary Directorory for Word Game

Each server program program recognizes a file named `<local-code>-words.txt` in
its own 'dict' directory as the word list for the language designated by _local-code_.
However, these are generally symbolic links to the dictionaries in the 
main 'dict' directory of the project, $WORKSPACE/dict.

Currently we only have an English dictionary:

- moby-english.txt - 
    
    Derived from CROSSWD.TXT of the project Gutenberg Moby free ebook: 
    http://www.gutenberg.org/files/3201/3201.txt
    http://www.gutenberg.org/files/3201/files/CROSSWD.TXT.
      
      `dos2unix CROSSWD.TXT`

    Note other files in the ebook may contain special characters. If you 
    decide to use them, remove the words with special characters:
    
      `egrep "^[a-zA-Z]+$" file 


To experiment with different dictionaries, symbolically link 
`<server-dir>/dict/<local-code>-words.txt` to your own word file.

For example, to use the English spell checker dictionary on unix-based platforms
for the scala-server, link as follows: 

    `ln -s /usr/share/dict/words $WORKSPACE/scala-server/dict/en-words.txt`


