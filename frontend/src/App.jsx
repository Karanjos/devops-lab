import { useCallback, useEffect, useState } from 'react'
import { createOrder, listOrders } from './api'

const POLL_MS = 2000

function elapsed(order) {
  if (!order.processedAt) return null
  const ms = new Date(order.processedAt) - new Date(order.createdAt)
  return ms < 1000 ? `${ms} ms` : `${(ms / 1000).toFixed(1)} s`
}

function OrderForm({ onPlaced }) {
  const [customer, setCustomer] = useState('')
  const [item, setItem] = useState('')
  const [quantity, setQuantity] = useState(1)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState(null)

  async function handleSubmit(event) {
    event.preventDefault()
    setBusy(true)
    setError(null)
    try {
      await createOrder({ customer, item, quantity: Number(quantity) })
      setItem('')
      setQuantity(1)
      onPlaced()
    } catch {
      setError('The order was not placed. Check the details and try again.')
    } finally {
      setBusy(false)
    }
  }

  return (
    <form className="form" onSubmit={handleSubmit}>
      <h2>Place an order</h2>
      <label>
        Customer
        <input value={customer} onChange={(e) => setCustomer(e.target.value)} maxLength={80} required />
      </label>
      <label>
        Item
        <input value={item} onChange={(e) => setItem(e.target.value)} maxLength={80} required />
      </label>
      <label>
        Quantity
        <input
          type="number"
          min="1"
          max="1000"
          value={quantity}
          onChange={(e) => setQuantity(e.target.value)}
          required
        />
      </label>
      <button type="submit" disabled={busy}>
        {busy ? 'Placing order…' : 'Place order'}
      </button>
      {error && <p className="error" role="alert">{error}</p>}
    </form>
  )
}

function Track({ order }) {
  const done = order.status === 'PROCESSED'
  return (
    <div className={`track ${done ? 'is-done' : 'is-waiting'}`}>
      <div className="track-line" aria-hidden="true">
        <span className="node on" />
        <span className="rail"><span className="rail-fill" /></span>
        <span className={`node ${done ? 'on' : ''}`} />
      </div>
      <div className="track-labels">
        <span>Received</span>
        <span>{done ? `Processed in ${elapsed(order)}` : 'Processing'}</span>
      </div>
    </div>
  )
}

function OrderList({ orders }) {
  if (orders.length === 0) {
    return (
      <p className="empty">
        No orders yet. Place one and watch it move from received to processed.
      </p>
    )
  }
  return (
    <ol className="orders">
      {orders.map((order) => (
        <li key={order.id}>
          <div className="what">
            <span className="item">
              <span className="qty">{order.quantity}×</span> {order.item}
            </span>
            <span className="who">
              {order.customer} at {new Date(order.createdAt).toLocaleTimeString()}
            </span>
          </div>
          <Track order={order} />
        </li>
      ))}
    </ol>
  )
}

export default function App() {
  const [orders, setOrders] = useState([])
  const [online, setOnline] = useState(true)
  const [loaded, setLoaded] = useState(false)

  const refresh = useCallback(async () => {
    try {
      setOrders(await listOrders())
      setOnline(true)
    } catch {
      setOnline(false)
    } finally {
      setLoaded(true)
    }
  }, [])

  useEffect(() => {
    refresh()
    const timer = setInterval(refresh, POLL_MS)
    return () => clearInterval(timer)
  }, [refresh])

  return (
    <div className="page">
      <header className="masthead">
        <h1>Order desk</h1>
        <p className={`status ${online ? 'ok' : 'down'}`} role="status">
          {online ? 'Connected to the API' : 'API unreachable'}
        </p>
      </header>

      {!online && loaded && (
        <p className="banner" role="alert">
          The API is not responding. Start the backend (make up), then this page will recover on its own.
        </p>
      )}

      <main className="layout">
        <OrderForm onPlaced={refresh} />
        <section aria-labelledby="orders-heading">
          <h2 id="orders-heading">Orders</h2>
          <OrderList orders={orders} />
        </section>
      </main>
    </div>
  )
}
