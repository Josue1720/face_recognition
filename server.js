const express = require('express');
const mongoose = require('mongoose');
const multer = require('multer');
const cors = require('cors');
const fs = require('fs');

require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

mongoose.connect('mongodb://localhost:27017/employeeDB', {
    useNewUrlParser: true,
    useUnifiedTopology: true
}).then(() => console.log("MongoDB Connected"));

const employeeSchema = new mongoose.Schema({
    fullName: String,
    employeeId: String,
    image: String,
});

const Employee = mongoose.model('Employee', employeeSchema);

const storage = multer.diskStorage({
    destination: './uploads',
    filename: (req, file, cb) => {
        cb(null, Date.now() + '-' + file.originalname);
    }
});

const upload = multer({ storage });

app.post('/api/register', upload.single('image'), async (req, res) => {
    const { fullName, employeeId } = req.body;
    const imagePath = req.file.path;

    const employee = new Employee({ fullName, employeeId, image: imagePath });
    await employee.save();
    res.json({ message: "Registration successful!" });
});

app.listen(5000, () => console.log("Server running on port 5000"));
