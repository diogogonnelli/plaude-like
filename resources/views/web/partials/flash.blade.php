@if (session('status'))
    <div class="inline-success">
        {{ session('status') }}
    </div>
@endif

@if ($errors->any())
    <div class="inline-error">
        <ul class="list-plain">
            @foreach ($errors->all() as $message)
                <li>{{ $message }}</li>
            @endforeach
        </ul>
    </div>
@endif
