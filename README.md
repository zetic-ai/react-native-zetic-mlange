# React-Native-Zetic

A React Native module that provides a bridge to run on-device AI models with high performance using native implementations in Kotlin (Android) and Swift (iOS).

It's provided by Zetic

[![npm version](https://img.shields.io/npm/v/react-native-zetic-mlange.svg)](https://www.npmjs.com/package/react-native-zetic-mlange)
[![license](https://img.shields.io/github/license/zetic-ai/react-native-zetic-mlange.svg)](LICENSE)

## Features

- 🚀 Run AI models directly on device with native performance
- 📱 Cross-platform support for both iOS and Android
- 🔒 Secure model management with authentication
- 💾 Automatic model downloading and caching
- 🔋 Efficient memory management

## Installation

```sh
npm install react-native-zetic-mlange
# or
yarn add react-native-zetic-mlange
```

### iOS

```sh
cd ios && pod install
```

### Android

No additional steps required for Android as the module is auto-linked.

## Usage

```javascript
import Zetic from 'react-native-zetic-mlange';

// Initialize the model
const initModel = async () => {
  try {
    await Zetic.create('YOUR_PERSONAL_ACCESS_TOKEN', 'YOUR_MODEL_KEY');
    console.log('Model initialized successfully');
  } catch (error) {
    console.error('Failed to initialize model:', error);
  }
};

// Run inference with the model
const runInference = async (inputData) => {
  try {
    // inputData should be a 2D array of numbers
    const result = await Zetic.run(inputData);
    console.log('Model output:', result);
    return result;
  } catch (error) {
    console.error('Error running inference:', error);
    throw error;
  }
};

// Clean up when done
const cleanup = async () => {
  try {
    await Zetic.deinit();
    console.log('Model resources released');
  } catch (error) {
    console.error('Error cleaning up:', error);
  }
};
```

## API Reference

### `create(personalAccessToken, modelKey)`

Initializes the on-device AI model.

- **Parameters**:
  - `personalAccessToken` (string): Your personal access token for authentication
  - `modelKey` (string): The specific model key you want to use
- **Returns**: Promise that resolves when the model is successfully initialized and downloaded
- **Throws**: Error if initialization fails

### `run(inputData)`

Runs inference using the initialized model.

- **Parameters**:
  - `inputData` (any[][]): 2D array of input values
- **Returns**: Promise that resolves with the model's output data
- **Throws**: Error if the model hasn't been initialized or if inference fails

### `deinit()`

Releases resources used by the model.

- **Returns**: Promise that resolves when cleanup is complete
- **Throws**: Error if cleanup fails

## Example

```javascript
import React, { useEffect, useState } from 'react';
import { Button, StyleSheet, Text, View } from 'react-native';
import Zetic from 'react-native-zetic-mlange';

export default function App() {
  const [result, setResult] = useState(null);
  const [isModelReady, setIsModelReady] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => {
    // Initialize model when component mounts
    initializeModel();
    
    // Clean up when component unmounts
    return () => {
      Zetic.deinit()
        .then(() => console.log('Model cleaned up'))
        .catch(err => console.error('Cleanup error:', err));
    };
  }, []);

  const initializeModel = async () => {
    try {
      await Zetic.create('YOUR_PERSONAL_ACCESS_TOKEN', 'YOUR_MODEL_KEY');
      setIsModelReady(true);
      setError(null);
    } catch (err) {
      setError(`Initialization error: ${err.message}`);
    }
  };

  const runModel = async () => {
    if (!isModelReady) {
      setError('Model is not ready yet');
      return;
    }
    
    try {
      // Example input data
      const inputData = [
        [1.0, 2.0, 3.0],
        [4.0, 5.0, 6.0]
      ];
      
      const output = await Zetic.run(inputData);
      setResult(output);
      setError(null);
    } catch (err) {
      setError(`Inference error: ${err.message}`);
    }
  };

  return (
    <View style={styles.container}>
      <Text style={styles.status}>
        Model status: {isModelReady ? 'Ready' : 'Not Ready'}
      </Text>
      
      {error && <Text style={styles.error}>{error}</Text>}
      
      <Button
        title="Run Model"
        onPress={runModel}
        disabled={!isModelReady}
      />
      
      {result && (
        <View style={styles.result}>
          <Text style={styles.resultTitle}>Results:</Text>
          <Text>{JSON.stringify(result, null, 2)}</Text>
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20,
  },
  status: {
    fontSize: 18,
    marginBottom: 20,
  },
  error: {
    color: 'red',
    marginBottom: 20,
  },
  result: {
    marginTop: 20,
    padding: 10,
    backgroundColor: '#f0f0f0',
    borderRadius: 5,
    width: '100%',
  },
  resultTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    marginBottom: 10,
  },
});
```

## Requirements

- React Native >= 0.72.0
- iOS 12.0 or later
- Android API level 21 or later

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For any issues or feature requests, please file an issue on the [GitHub repository](https://github.com/zetic-ai/react-native-zetic-mlange/issues).