# gemini-linux-ai-assistant

A simple Bash AI assistant integrated into Linux with multiple functionalities.

With this script, it's technically possible to have an AI assistant on Linux that performs tasks for the user through natural language interaction, allowing even non-technical users to engage with Linux on a deeper level.

![image](https://github.com/user-attachments/assets/2a5bb54c-6052-4220-82ae-e9e80fb7088d)

It supports:

- **Image evaluation**: The script triggers a screenshot using *Spectacle*. After taking the screenshot, it prompts the user to ask a question about the image. Gemini then analyzes the screenshot and provides an answer based on its content.  
  For example, if the screenshot shows a file explorer and the question is "Where are my pictures?", Gemini may respond by identifying which folders are likely to contain pictures.  
  ![image](https://github.com/user-attachments/assets/d0b083f9-42e6-4671-a6d5-5fb7f835172a)

- **Text input fallback**: If the screenshot is canceled by pressing `Esc`, the script will prompt for a text question instead. Gemini will respond to the question just like a standard chatbot.  
  ![image](https://github.com/user-attachments/assets/d8106ea1-64ac-495d-b7d4-af5956270de2)

- **Running system commands directly**: If Gemini’s response includes a Bash command, a Konsole window will appear showing the command and asking the user for confirmation before execution.  
  For example, if the question is "How do I power off my computer?", Gemini may respond with `shutdown`, and a Konsole window will appear with the command, waiting for the user to press Enter to execute it.  
  ![image](https://github.com/user-attachments/assets/6814dc54-9f38-4da5-94ac-30c6688f11b4)

- **Short time memory**: When clicking "Ask again" it's possible to ask another question and Gemini will take in mind the context from the last question and answer given, answering the new question according to it.
<img width="726" height="556" alt="image" src="https://github.com/user-attachments/assets/dc5326d4-8250-48cb-ac3a-966ad1627eb0" />

It is recommended to set up a shortcut to run the script, such as `Ctrl + Win + PrtSc`.

---

# Requirements

Currently, the script uses KDE Plasma tools. They can be installed on any system, but using the KDE desktop environment is recommended.

Dependencies:

- `spectacle`
- `zenity`
- `imagemagick`
- `curl`
- `jq`
- `konsole`

---

# Run

To run on a Linux system:

Setup your Google API key with:

```bash
export GOOGLE_API_KEY=your_key_here
```
Or just change the api variable in the code.

Then run:

```bash
chmod +x ./gemini-linux-ai-assistant.sh
./gemini-linux-ai-assistant.sh
```
