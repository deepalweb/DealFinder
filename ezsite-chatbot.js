/**
 * 通过API加载气泡脚本
 */
(function () {
  // 嵌入聊天机器人
  function chatbotEmbed(data = {}) {
    // 检查是否启用聊天机器人
    if (data && data.EnableChatbot) {
      // 创建配置脚本
      const configScript = document.createElement('script');
      configScript.textContent = `
          window.chatpilotConfig = {
            chatbotId: "${data.SerialNumber}",
            domain: "https://www.newoaks.ai"
          }
        `;
      document.head.appendChild(configScript);

      // 创建加载脚本
      const embedScript = document.createElement('script');
      embedScript.src = 'https://www.newoaks.ai/embed.min.js';
      embedScript.charset = 'utf-8';
      embedScript.defer = true;
      document.head.appendChild(embedScript);
    }
  }

  // 检查并获取项目信息
  window.ezsite = window.ezsite || {};
  if (!window.ezsite.projectInfo) {
    const isProduction = location.protocol === 'https:';
    const apiEndpoint = `https://usapi.hottask.com/${
      isProduction ? 'autodev' : 'stagingautodev'
    }/Project/GetProjectInfo`;
    fetch(apiEndpoint, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        host: window.location.host
      })
    })
      .then((response) => response.json())
      .then((res) => {
        const data = res.Data;
        if (!res.Success) {
          return console.error('request error:', data);
        }
        window.ezsite.projectInfo = data;
        chatbotEmbed(data);
      })
      .catch((error) => {
        console.error('request catch error:', error);
      });
  } else {
    chatbotEmbed(window.ezsite.projectInfo);
  }
})();
