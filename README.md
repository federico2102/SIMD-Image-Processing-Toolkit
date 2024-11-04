# Image Processing with SIMD: A Performance Comparison

## Project Overview
This project focuses on implementing various image filters using both C and Assembly with SIMD (Single Instruction, Multiple Data) instructions. The goal is to explore and analyze the performance differences between C and Assembly implementations, utilizing vectorized programming for efficient image processing. The filters developed include color transformations, edge detection, and custom effects, applied to BMP images. The project emphasizes optimization, performance analysis, and the scientific approach to evaluating different implementations.

## Technologies Used
- **Programming Languages**: C, Assembly (x86-64)
- **SIMD Instruction Set**: SSE (Streaming SIMD Extensions)
- **Tools and Frameworks**:
  - GNU Make for build automation
  - Custom BMP library for image handling
  - Performance measurement tools (e.g., `rdtsc` for cycle counting)
  - ImageMagick (for image transformations in tests)
- **Operating System**: Linux-based systems for compatibility

## Project Structure
The project is organized as follows:
- **`/code`**: Contains the source code and Makefile for compiling the project.
- **`/filtros`**: Implementations of the filters in both C and Assembly.
- **`/helper`**: BMP library sources and image comparison tool.
- **`/test`**: Scripts for automated testing and memory checks.
- **`/img`**: Sample images for testing and performance analysis.

## Implemented Filters
- **Blit**: Combines two images while preserving certain pixels.
- **Monochrome**: Converts an image to grayscale.
- **Temperature**: Adjusts the color temperature of the image.
- **Edge Detection**: Highlights edges within the image for feature extraction.
- **Wave Effect**: Applies a wave-like distortion to the image.

## Key Skills Demonstrated
### 1. **SIMD and Vectorized Programming**
- Utilized SSE instructions to process multiple pixels simultaneously, significantly improving the performance of image filters.
- Managed data alignment and memory access patterns to maximize the benefits of vectorized operations.

### 2. **Memory Management**
- Implemented efficient memory handling to process large image data without unnecessary overhead.
- Ensured that image data was processed in blocks (e.g., 16 bytes at a time) to align with cache line sizes.

### 3. **Performance Analysis**
- Measured execution times using the `rdtsc` instruction to obtain precise cycle counts.
- Compared and analyzed the performance of C versus Assembly implementations under various conditions.
- Implemented methodologies to minimize interference from context switches and dynamic CPU frequency changes.

### 4. **Low-Level Optimization**
- Handled edge cases where SIMD processing was not feasible, demonstrating the ability to fall back to scalar operations where needed.
- Analyzed and optimized code paths to reduce conditional branches and improve cache access patterns.

### 5. **Scientific Reporting**
- Conducted rigorous testing and created reports comparing implementation results, including analysis of trade-offs in precision and execution time.
- Used visual and quantitative data to support hypotheses on performance differences.

## How to Run
1. **Compilation**: Run `make` from the `code` directory to build the project.
2. **Usage**: Execute `./tp2 [options] [filter_name] [input_image] [parameters...]`.
   - Example: `./tp2 -i asm blit input.bmp`.
3. **Testing**: Run scripts in the `test` folder to validate functionality and performance.

## Conclusion
This project not only highlights proficiency in C and Assembly programming but also demonstrates a strong understanding of SIMD optimization, memory management, and low-level performance tuning. The comparison of implementations showcases the ability to evaluate and optimize code in a scientific manner, emphasizing both technical depth and practical application.

---

