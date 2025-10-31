# 1️⃣ Start from a base image with Python pre-installed
FROM python:3.9-slim

# 2️⃣ Set a working directory inside the container
WORKDIR /app

# 3️⃣ Copy your dependencies file into the container
COPY requirements.txt ./

# 4️⃣ Install dependencies (Flask, boto3, etc.)
RUN pip install --no-cache-dir -r requirements.txt

# 5️⃣ Copy the rest of your project files into the container
COPY . .

# 6️⃣ Expose the port your app runs on
EXPOSE 8080

# 7️⃣ Define the command to start your Flask app
CMD ["python", "app.py"]
