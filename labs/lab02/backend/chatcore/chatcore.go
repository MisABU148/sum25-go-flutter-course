package chatcore

import (
	"context"
	"errors"
	"sync"
)

// Broker handles message routing between users
type Broker struct {
	ctx        context.Context
	input      chan Message
	users      map[string]chan Message
	usersMutex sync.RWMutex
	done       chan struct{}
}

func NewBroker(ctx context.Context) *Broker {
	return &Broker{
		ctx:   ctx,
		input: make(chan Message, 100),
		users: make(map[string]chan Message),
		done:  make(chan struct{}),
	}
}

// Run starts the broker event loop
func (b *Broker) Run() {
	for {
		select {
		case <-b.ctx.Done():
			// On context cancel, shutdown broker
			b.usersMutex.Lock()
			for _, ch := range b.users {
				close(ch)
			}
			b.usersMutex.Unlock()
			close(b.done)
			return
		case msg := <-b.input:
			if msg.Broadcast {
				// Send to all users
				b.usersMutex.RLock()
				for userID, ch := range b.users {
					// Avoid blocking: send in a goroutine
					select {
					case ch <- msg:
					default:
						// If user channel is full, drop message to avoid blocking broker
					}
					_ = userID // for clarity, no use
				}
				b.usersMutex.RUnlock()
			} else {
				// Private message: send to recipient only
				b.usersMutex.RLock()
				ch, ok := b.users[msg.Recipient]
				b.usersMutex.RUnlock()
				if ok {
					select {
					case ch <- msg:
					default:
						// drop if user channel full
					}
				}
			}
		}
	}
}

// SendMessage sends a message to the broker
func (b *Broker) SendMessage(msg Message) error {
	select {
	case <-b.ctx.Done():
		return errors.New("broker context canceled")
	case b.input <- msg:
		return nil
	}
}

// RegisterUser adds a user to the broker
func (b *Broker) RegisterUser(userID string, recv chan Message) {
	b.usersMutex.Lock()
	defer b.usersMutex.Unlock()
	b.users[userID] = recv
}

// UnregisterUser removes a user from the broker
func (b *Broker) UnregisterUser(userID string) {
	b.usersMutex.Lock()
	defer b.usersMutex.Unlock()
	if ch, ok := b.users[userID]; ok {
		close(ch)
		delete(b.users, userID)
	}
}
