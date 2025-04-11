require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "ZeticRN"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.authors      = package["author"]

  s.platforms    = { :ios => min_ios_version_supported }
  s.source       = { :git => ".git", :tag => "#{s.version}" }

  s.source_files = "ios/**/*.{h,m,mm,swift}"

# Use install_modules_dependencies helper to install the dependencies if React Native version >=0.71.0.
# See https://github.com/facebook/react-native/blob/febf6b7f33fdb4904669f99d795eba4c0f95d7bf/scripts/cocoapods/new_architecture.rb#L79.
if respond_to?(:install_modules_dependencies, true)
  install_modules_dependencies(s)
else
  s.dependency "React-Core"
end


s.prepare_command = <<-CMD
FRAMEWORK_NAME="ZeticMLange"
GITHUB_REPO="zetic-ai/ZeticMLangeiOS"
GITHUB_RELEASE_TAG="1.1.0"
DOWNLOAD_URL="https://github.com/${GITHUB_REPO}/releases/download/${GITHUB_RELEASE_TAG}/${FRAMEWORK_NAME}.xcframework.zip"
FRAMEWORK_DIR="ios/Frameworks"
FRAMEWORK_PATH="${FRAMEWORK_DIR}/${FRAMEWORK_NAME}.xcframework"

# Create log file
LOG_FILE="zeticmlange_installation.log"
if [ -d ${LOG_FILE} ]; then
  rm ${LOG_FILE}
fi

echo "$(date): === Starting Zetic framework installation ==="

# Ensure we have a clean directory - remove existing framework if present
if [ -d "${FRAMEWORK_PATH}" ]; then
  echo "Removing existing framework at: ${FRAMEWORK_PATH}" | tee -a ${LOG_FILE}
  rm -rf "${FRAMEWORK_PATH}"
fi

# Create directory for the framework
mkdir -p ${FRAMEWORK_DIR}

echo "=== Installing Zetic framework from GitHub ===" | tee -a ${LOG_FILE}
echo "Downloading from: ${DOWNLOAD_URL}" | tee -a ${LOG_FILE}

# Download the XCFramework
curl -L ${DOWNLOAD_URL} -o ${FRAMEWORK_DIR}/${FRAMEWORK_NAME}.xcframework.zip 2>&1 | tee -a ${LOG_FILE}

if [ $? -ne 0 ]; then
  echo "❌ Error: Failed to download XCFramework" | tee -a ${LOG_FILE}
  exit 1
fi

# Unzip the Zetic framework with overwrite flag
unzip -o ${FRAMEWORK_DIR}/${FRAMEWORK_NAME}.xcframework.zip -d ${FRAMEWORK_DIR}/ 2>&1 | tee -a ${LOG_FILE}

if [ $? -ne 0 ]; then
  echo "❌ Error: Failed to unzip XCFramework" | tee -a ${LOG_FILE}
  exit 1
fi

# Clean up the zip file
rm ${FRAMEWORK_DIR}/${FRAMEWORK_NAME}.xcframework.zip

# Verify installation
if [ -d "${FRAMEWORK_PATH}" ]; then
  echo "✅ XCFramework successfully installed at: ${FRAMEWORK_PATH}" | tee -a ${LOG_FILE}
  echo "=== Installation Complete ===" | tee -a ${LOG_FILE}
else
  echo "❌ Error: Zetic framework installation failed. Path does not exist: ${FRAMEWORK_PATH}" | tee -a ${LOG_FILE}
  exit 1
fi

echo ""
echo "========================================================================"
echo "🔍 Zetic framework installation details in: ${LOG_FILE}"
echo "========================================================================"
echo ""
CMD

s.vendored_frameworks = "ios/Frameworks/ZeticMLange.xcframework"

end
