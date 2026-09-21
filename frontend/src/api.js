// All calls use relative URLs: Vite proxies /api in dev, Nginx proxies it in Docker/Kubernetes.

async function request(path, options) {
  const response = await fetch(path, {
    headers: { 'Content-Type': 'application/json' },
    ...options,
  })
  if (!response.ok) {
    throw new Error(`Request failed with status ${response.status}`)
  }
  return response.json()
}

export const listOrders = () => request('/api/orders')

export const createOrder = (order) =>
  request('/api/orders', { method: 'POST', body: JSON.stringify(order) })
