function randomizeStyles() {
    const header = document.getElementById('header');
    
    // Array of fonts
    const fonts = [
        'Arial', 'Verdana', 'Georgia', 'Times New Roman', 'Courier New',
        'Trebuchet MS', 'Lucida Sans', 'Tahoma', 'Arial Black', 'Comic Sans MS',
        'Impact', 'Consolas', 'Garamond', 'Palatino Linotype', 'Segoe UI'
    ];
    
    // Random background color
    const randomBg = `rgb(${Math.random() * 255}, ${Math.random() * 255}, ${Math.random() * 255})`;
    document.body.style.backgroundColor = randomBg;
    
    // Random text color
    const randomColor = `rgb(${Math.random() * 255}, ${Math.random() * 255}, ${Math.random() * 255})`;
    header.querySelector('h1').style.color = randomColor;
    
    // Random font
    const randomFont = fonts[Math.floor(Math.random() * fonts.length)];
    header.querySelector('h1').style.fontFamily = randomFont;
    
    // Random font size between 2rem and 8rem
    const randomSize = 2 + Math.random() * 6;
    header.querySelector('h1').style.fontSize = `${randomSize}rem`;
}

// Helper function to get the inverted color
function invertColor(hex) {
    let r = parseInt(hex.slice(1, 3), 16);
    let g = parseInt(hex.slice(3, 5), 16);
    let b = parseInt(hex.slice(5, 7), 16);

    // Invert the colors
    r = 255 - r;
    g = 255 - g;
    b = 255 - b;

    // Convert to RGB format
    return `rgb(${r}, ${g}, ${b})`;
}
